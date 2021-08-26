# Advanced - Geo, Advanced Search, Custom Config and more

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Cloud Services](environment_advanced_services.md)
- [**GitLab Environment Toolkit - Advanced - Geo, Advanced Search, Custom Config and more**](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)

The Toolkit by default will deploy the latest version of the selected [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/). However, it can also support other advanced setups such as Geo or different component makeups such as Gitaly Sharded.

On this page we'll detail all of the supported advanced setups you can do with the Toolkit. We recommend you only do these setups if you have a good working knowledge of both the Toolkit and what the specific setups involve.

[[_TOC_]]

## Geo

When provisioning a Geo deployment there are a few differences to a single environment that need to be made throughout the process to allow the Toolkit to properly manage the deployment:

- Both environments should share the same admin credentials. For example in the case of GCP the same Service Account.
- The GitLab license is shared between the 2 sites. This means the license only needs to be applied to the primary site.

As shown above, for the most part, the process is the same as when creating a single environment and as such the standard Toolkit steps defined in the earlier docs must be followed before creating a Geo deployment.

The process used to build the environments follows the documentation for [Geo for multiple nodes](https://docs.gitlab.com/ee/administration/geo/replication/multiple_servers.html). The high level steps that will be followed are:

1. Provision 2 environments with Terraform
    - Each environment will share some common labels to identify them as being part of the same Geo deployment
    - One environment will be identified as being a Primary site and one will be a Secondary
1. Configure the environments with Ansible
    - Each environment will work as a separate environment until Geo is configured
1. Configure Geo on the Primary and Secondary sites

### Terraform

When creating a new Terraform site for Geo it is recommended to create a new subfolder for your Geo deployment with 2 sub-folders below that for the primary and secondary config. Although not required this does help to keep all the config for a single Geo deployment in one location. The 2 separate environments however will always still need their own folders here for Terraform to manage their State correctly.

```bash
my-geo-deployment
    ├── primary
    └── secondary
```

After this it is recommended to copy an existing reference architecture for the primary and secondary folders. You could copy the 25k reference architecture to use as your primary site and the 3k for your secondary, or use 5k for both your primary and secondary sites, the Geo process will work for any combination with the same steps.

The main steps for [GitLab Environment Toolkit - Building environments](environment_provision.md) should be followed when creating a new Terraform project.

Once you have copied the desired architecture sizes we will need to modify them to allow for Geo. The first step is to adjust the `ref_arch` module source variable to point to the right location if you've followed the folder structure above. You will need to add an additional `../` to the path as we are now using sub-folders. For example:

```tf
module "gitlab_ref_arch_*" {
  source = "../../modules/gitlab_ref_arch_*"

  [...]
```

Next you need to add 2 new labels that helps to identify the machines as belonging to our Geo deployment and if they are part of the primary or secondary site:

- `geo_site` - used to identify if a machine belongs to the primary or secondary site. This must be set to either `geo-primary-site` or `geo-secondary-site`.
- `geo_deployment` - used to identify that a primary and secondary site belong to the same Geo deployment. This must be unique across all Geo deployments thats will be stored alongside each other.

The recommended way to do this is to first set them in the `variables.tf` file, for example:

```tf
variable "geo_site" {
    default = "geo-primary-site"
}

variable "geo_deployment" {
    default = "my-geo-deployment"
}
```

Next you should add them into the selected cloud providers module's call under `environment.tf`:

```tf
module "gitlab_ref_arch_*" {
  source = "../../modules/gitlab_ref_arch_*"

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  [...]
```

> When using repmgr on the secondary site the `node_count` in `postgres.tf` should be set to 1 for the secondary sites config. When using Patroni, this can be left at its original value.

Once each site is configured we can run the `terraform apply` command against each project. You can run this command against the primary and secondary sites at the same time.

### Ansible

We will need to start by creating new inventories for a Geo deployment. For Geo we will require 3 inventories: `primary`, `secondary` and `all`. It is recommended to store these in one parent folder to keep all the config together.

```bash
ansible
└── environments
    └── my-geo-deployment
        ├── files
        └── inventory
            ├── all
            ├── primary
            └── secondary
```

For Omnibus environments the `primary` and `secondary` folders are treated the same as non Geo environments and as such the steps for [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md) should be followed.

However you should remove the GitLab license from the secondary site before running the `ansible-playbook` command. To remove the license from the secondary site you can just remove the `gitlab_license_file` setting from the secondary `vars.yml` file.

For Cloud Native Hybrid environments some variables will need to be added to the primary and secondary `vars.yml` files.

Primary `vars.yml`:

```yml
cloud_native_hybrid_geo: true
cloud_native_hybrid_geo_role: primary
```

Secondary `vars.yml`:

```yml
cloud_native_hybrid_geo: true
cloud_native_hybrid_geo_role: secondary
```

Also for Omnibus and Cloud Native Hybrid environments it's required to add a new `keyed_group` to your Dynamic Inventory config file for your chosen cloud provider:

GCP:

```yaml
- key: labels.gitlab_geo_site
    separator: ''
```

AWS:

```yaml
- key: tags.gitlab_geo_site
  separator: ''
```

Azure:

```yaml
- prefix: ''
  separator: ''
  key: tags.gitlab_geo_site | default('ungrouped')
```

Once the inventories for primary and secondary are complete you can use Ansible to configure GitLab. Once complete you will have 2 independent instances of GitLab. The primary site should have a license installed and the secondary will not.
As these environments are still separate from each other at this point, they can be built at the same time and are not reliant on each other. Once complete you should be able to log into each environment before continuing.

The `all` inventory is very similar to the `primary` and `secondary`, it allows Ansible to see both sites instead of one for the tasks that require coordination across both environments. To create the `all` inventory files it is easiest to copy them from `primary` and modify some values as follows:

#### Dynamic Inventory - `all.*.yml`

The Dynamic Inventory file for `all` Geo machines will be almost the same as the normal inventory files except for the following changes:

- The `filters` should be changed to follow the `gitlab_geo_deployment` label / tag. The normal filter is based on an environment's prefix, unique to each environment. The Geo deployment label / tag is how we identify multiple environments to run our Geo configuration against.
- Two new keys should be added to the `keyed_groups` section for the additional `gitlab_geo_site` and `gitlab_geo_full_role` labels / tags respectively. `gitlab_geo_full_role` is a label / tag that is created for us by the Terraform module, this label is a combination of `geo_site`, `node_type` and `node_level`. Using this we can get the IP of a machine directly by its role in a Geo deployment from a single label.

Dynamic Inventories differ slightly based on Cloud Provider. Below are full examples of Geo `all` Dynamic Inventory files for each Cloud Provider:

GCP:

```yaml
plugin: gcp_compute
projects:
  - <gcp_project_id>
filters:
  - labels.gitlab_geo_deployment = my-geo-deployment
keyed_groups:
  - key: labels.gitlab_node_type
    separator: ''
  - key: labels.gitlab_node_level
    separator: ''
  - key: labels.gitlab_geo_site
    separator: ''
  - key: labels.gitlab_geo_full_role
    separator: ''
scopes:
  - https://www.googleapis.com/auth/compute
hostnames:
  # List host by name instead of the default public ip
  - name
compose:
  # Set an inventory parameter to use the Public IP address to connect to the host
  # For Private ip use "networkInterfaces[0].networkIP"
  ansible_host: networkInterfaces[0].accessConfigs[0].natIP
```

AWS:

```yaml
plugin: aws_ec2
regions:
  - us-east-1
filters:
  tag:gitlab_geo_deployment: my-geo-deployment
keyed_groups:
  - key: tags.gitlab_node_type
    separator: ''
  - key: tags.gitlab_node_level
    separator: ''
  - key: tags.gitlab_geo_site
    separator: ''
  - key: tags.gitlab_geo_full_role
    separator: ''
hostnames:
  # List host by name instead of the default public ip
  - tag:Name
compose:
  # Use the public IP address to connect to the host
  # (note: this does not modify inventory_hostname, which is set via I(hostnames))
  ansible_host: public_ip_address
```

Azure:

```yml
plugin: azure.azcollection.azure_rm

include_vm_resource_groups:
  - "<resource_group_name>"

keyed_groups:
  - prefix: ''
    separator: ''
    key: tags.gitlab_node_type | default('ungrouped')
  - prefix: ''
    separator: ''
    key: tags.gitlab_node_level | default('ungrouped')
  - prefix: ''
    separator: ''
    key: tags.gitlab_geo_site | default('ungrouped')
  - prefix: ''
    separator: ''
    key: tags.gitlab_geo_full_role | default('ungrouped')
```

#### Environment config - `vars.yml`

Add the line `secondary_external_url` which needs to match the `external_url` in the `secondary` inventory vars file.

You can also remove the properties: `prefix`, `gitlab_license_file` and any password vars with the exception of `postgres_password` which is still required. These are not used when configuring Geo and as such should only be set in the `primary` and `secondary` inventories.

For Cloud Native Hybrid environments you will need to leave some of the password variables in the `vars.yml` file as well as adding some Geo specific variables:

```yml
# Geo Settings
cloud_native_hybrid_geo: true
geo_primary_site_prefix: "<geo_primary_site_prefix>"
geo_secondary_site_prefix: "<geo_secondary_site_prefix>"

# GCP Specific Settings
geo_primary_site_gcp_project: "<geo_primary_site_gcp_project>"
geo_primary_site_gcp_zone: "<geo_primary_site_gcp_zone>"
geo_secondary_site_gcp_project: "<geo_secondary_site_gcp_project>"
geo_secondary_site_gcp_zone: "<geo_secondary_site_gcp_zone>"

# AWS Specific Settings
geo_primary_site_aws_region: "<geo_primary_site_aws_region>"
geo_secondary_site_aws_region: "<geo_secondary_site_aws_region>"

# Passwords / Secrets
gitlab_root_password: '<gitlab_root_password>'
postgres_password: '<postgres_password>'
redis_password: '<redis_password>'
praefect_external_token: '<praefect_external_token>'
gitaly_token: '<gitaly_token>'
grafana_password: '<grafana_password>'
```

Once done we can then run the command `ansible-playbook -i environments/my-geo-deployment/inventory/all gitlab-geo.yml`.

Once complete the 2 sites will now be part of the same Geo deployment.

## Advanced Search with Elasticsearch

The Toolkit supports automatically setting up GitLab's [Advanced Search](https://docs.gitlab.com/ee/integration/elasticsearch.html) functionality. This includes provisioning and configuring Elasticsearch nodes to be a cluster as well as configuring GitLab to use it.

Note that to be able to enable Advanced Search you'll require at least a GitLab Premium License.

Due to the nature of Elasticsearch it's difficult to give specific guidance on what size and shape the cluster should take as it's heavily dependent on things such as data, expected usage, etc... That being said [we do offer some guidance in our Elasticsearch docs](https://docs.gitlab.com/ee/integration/elasticsearch.html#guidance-on-choosing-optimal-cluster-configuration). For testing our data the Quality team has found a size similar to the Gitaly nodes in each Reference Architecture has sufficed so far.

Enabling Advanced Search on your environment is designed to be as easy possible and can be done as follows:

- Elasticsearch nodes should be provisioned as normal via Terraform.
- Once the nodes are available Ansible will automatically configure them, downloading and setting up the Elasticsearch Docker image.
  - At the time of writing the Elasticsearch version deployed is `7.6.2`. To deploy a different version you can set the `elastic_version`.
- The Toolkit will also setup a Kibana Docker container on the Primary Elasticsearch node for administration and debugging purposes. Kibana will be accessible on your external IP / URL and port `5602` by default, e.g. `http://<external_ip_or_url>:5602`.
- Ansible will then configure the GitLab environment near the end of its run to enable Advanced Search against those nodes and perform the first index.

## Custom Config

The Toolkit allows for you to provide custom GitLab config that will be used when setting up components via Omnibus or Helm charts.

**However, this feature must be used with the utmost caution**. Any custom config passed will always take precedence and may lead to various unintended consequences or broken environments if not used carefully.

Custom config should only be used in advanced scenarios where you are fully aware of the intended effects or for areas that the Toolkit doesn't support natively due to potential permutations such as:

- Omniauth
- Custom Object Storage
- Email

In this section we detail how to set up custom config for Omnibus and Helm charts components respectively.

### Omnibus

TBC

### Helm

Providing custom config for components run via Helm charts in Cloud Native Hybrid environments is done as follows:

1. Create a [GitLab Charts](https://docs.gitlab.com/charts/) yaml file in the correct format with the specific custom settings you wish to apply
1. By default the Toolkit will looks for a file named `gitlab_charts.yml` in the [environments](environment_configure.md#2-setup-the-environments-inventory-and-config) `files/config` folder path. E.G. `ansible/environments/<env_name>/files/config/gitlab_charts.yml`. Save your file in this location with the same name.
    - If you wish to store your file in a different location or use a different name the full path that Ansible should use can be set via the `gitlab_charts_custom_config_file` inventory variable.

With the above done the file will be picked up by the Toolkit and used when configuring the Helm charts.

## Container Registry

Container Registry is enabled by default if you're deploying [Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/#available-reference-architectures) configured with external SSL via GET using AWS cloud provider. Container Registry in that case will run in k8s and use an s3 bucket for storage.

## Disk Volume Configuration (GCP only)

Optionally, you may want to add disk volumes to Omnibus installed VMs. This may be useful if you want to put your data and logs on different disks.

In Terraform, you must provision the disks first using the `disks` variable, for example:

```tf
variable "disks" {
  disks = [
    {
      size    = 50
      type    = "pd-ssd"
      device_name = "data"
    },
    {
      size    = 20
      type    = "pd-standard"
      device_name = "log"
    },
  ]
}
```

In Ansible, set the `disk_mounts` variable to mount and format them when instances are configured, for example:

```yaml
disk_mounts:
  - { device_name: 'log', mount_dir: '/var/log/gitlab' }
  - { device_name: 'data', mount_dir: '/var/opt/gitlab' }
```

## Disable External IPs (GCP Only)

Optionally, you may want to disable External IPs on your provisioned nodes. This is done in Terraform with the `setup_external_ips` variable being set to false in your `environment.tf` file:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"
[...]

  setup_external_ips = false
}
```

Once set no external IPs will be created or added to your nodes.

In this setup however some tweaks will need to be made to ansible:

- It will need to be run from a box that can access the boxes via internal IPs
- When using the Dynamic Inventory it will need to be adjusted to return internal IPs. This can be done by changing the `compose.ansible_host` setting to `private_ip_address`
- The `external_url` setting should be set to the URL that the instance will be reachable internally
