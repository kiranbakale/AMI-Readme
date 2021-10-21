# Advanced - Custom Config, Data Disks, Advanced Search and more

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Cloud Services](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [**GitLab Environment Toolkit - Advanced - Custom Config, Data Disks, Advanced Search and more**](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)

The Toolkit by default will deploy the latest version of the selected [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/). However, it can also support other advanced setups such as Geo or different component makeups such as Gitaly Sharded.

On this page we'll detail all of the supported advanced setups you can do with the Toolkit. We recommend you only do these setups if you have a good working knowledge of both the Toolkit and what the specific setups involve.

[[_TOC_]]

## Custom Config

The Toolkit allows for you to provide custom GitLab config that will be used when setting up components via Omnibus or Helm charts.

**However, this feature must be used with the utmost caution**. Any custom config passed will always take precedence and may lead to various unintended consequences or broken environments if not used carefully.

Custom config should only be used in advanced scenarios where you are fully aware of the intended effects or for areas that the Toolkit doesn't support natively due to potential permutations such as:

- Omniauth
- Custom Object Storage
- Email

In this section we detail how to set up custom config for Omnibus and Helm charts components respectively.

### Omnibus

Providing custom config for components run as part of an Omnibus environment is done as follows:

1. Create a [gitlab.rb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template) file in the correct format with the specific custom settings you wish to apply
1. By default the Toolkit looks for a files in the [environments](environment_configure.md#2-setup-the-environments-inventory-and-config) `files/gitlab_configs` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_configs/<component>.rb`. Save your file in this location with the same name.
    - If you wish to store your file in a different location or use a different name the full path that Ansible should use can be set via a variable for each different component e.g. `<component>_custom_config_file`
    - Available component options: `consul`, `postgres`, `pgbouncer`, `redis`, `redis_cache`, `redis_persistent`, `praefect_postgres`, `praefect`, `gitaly`, `gitlab_rails`, `sidekiq` and `monitor`.

With the above done the file will be picked up by the Toolkit and used when configuring Omnibus.

### Helm

Providing custom config for components run via Helm charts in Cloud Native Hybrid environments is done as follows:

1. Create a [GitLab Charts](https://docs.gitlab.com/charts/) yaml file in the correct format with the specific custom settings you wish to apply
1. By default the Toolkit looks for a file named `gitlab_charts.yml` in the [environments](environment_configure.md#2-setup-the-environments-inventory-and-config) `files/gitlab_configs` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_configs/gitlab_charts.yml`. Save your file in this location with the same name.
    - If you wish to store your file in a different location or use a different name the full path that Ansible should use can be set via the `gitlab_charts_custom_config_file` inventory variable.

With the above done the file will be picked up by the Toolkit and used when configuring the Helm charts.

Additionally, the Toolkit provides an ability to pass a custom Chart task list that will run against the cluster before installing the [GitLab Charts](https://docs.gitlab.com/charts/). This feature could be used if you need some further customizations, for example creating custom secrets. When creating the file follow these requirements:

- The file should be a standard Ansible Tasks yaml file that will be used with [`include_tasks`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_tasks_module.html).
- By default, the Toolkit will look for a Chart Ansible Task file alongside your Ansible inventory in `environments/<inventory name>/files/gitlab_configs/charts_tasks.yml`.
  - If you want to store your custom task at another path then you can set the variable `gitlab_charts_custom_tasks_file` to point to your custom location.

### API

Some config in GitLab can only be changed via API. As such, the Toolkit supports passing a custom API Ansible Task list that will be executed during the [Post Configure](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/tree/main/ansible/roles/post-configure/tasks) role from [localhost](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/blob/main/ansible/post-configure.yml). This feature could be used when you want to do further configuration changes to your environment after it's deployed. For example, modifying GitLab [application settings using API](https://docs.gitlab.com/ee/api/settings.html).

Note that this file should be a standard Ansible Tasks yaml file that will be used with [`include_tasks`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_tasks_module.html).

By default, the Toolkit will look for an API Ansible Task file alongside your Ansible inventory in `environments/<inventory name>/files/gitlab_configs/api_tasks.yml`. If you want to store your custom task at another path then you can set the variable `post_configure_api_tasks_file` to point to your custom location.

## Custom Grafana Dashboards

When using the Toolkit it is possible to pass custom Grafana dashboards during setup to allow Grafana to monitor any metrics required by the user.

By default we recommend storing any custom dashboards alongside your Ansible inventory in `environments/<inventory name>/files/grafana/<collection name>/<dashboard files>`. You can create multiple folders to store different dashboards or store everything in a single folder. If you want to store your custom dashboards in a folder other than `environments/<inventory name>/files/grafana/` then you can set the variable `monitor_custom_dashboards_path` to point to your custom location.

Once the dashboards are in place you can add the `monitor_custom_dashboards` variable into your `vars.yml` file.

```yaml
monitor_custom_dashboards: [{ display_name: 'Sidekiq Dashboards', folder: "my_sidekiq_dashboards" }, { display_name: 'Gitaly Dashboards', folder: "my_gitaly_dashboards" }]
```

- `display_name`: This is how the collection will appear in the Grafana UI and the name of the folder the dashboards will be stored in on the Grafana server.
- `folder`: This is the name of the folder in `monitor_custom_dashboards_path` that holds your collection of dashboards.

## Data Disks (GCP, AWS)

The Toolkit supports provisioning and configuring extra disks, AKA data disks, for each group of machines (i.e. for all Gitaly nodes). With this set up you can have additional disk volumes mounted for storing data for added resilience and flexibility.

Like other resources the process here is similar - The disks are provisioned and attached via Terraform and then configured and mounted via Ansible. Below are sections detailing each step.

### Provisioning with Terraform

The first step is to provision and attach the disks to the selected machine groups.

This is done with Terraform and as such will require additional config in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file.

The config for this area is given per node type and is passed an array of hashes, where each hash represents a disk. Please note config differs between cloud providers and below are sections for each provider with full examples and descriptions below:

**GCP**

```tf
gitaly_disks = [
  { device_name = "data", size = 500, type = "pd-ssd" },
  { device_name = "logs", size = 50 }
]
```

- `*_disks` - The main setting for each node group.
  - `device_name` - The name _and_ block device identifier for each disk attached. Must be unique per machine. **Required**.
  - `size` - The size of the disk in GB. __Optional__, default is `100`.
  - `type` - The [type](https://cloud.google.com/compute/docs/disks) of the disk. __Optional__, default is `pd-standard`.

**AWS**

```tf
gitaly_data_disks = [
  { name = "data", device_name = "/dev/sdf", size = 500, iops = 8000 },
  { name = "logs", device_name = "/dev/sdg" }
]
```

- `*_data_disks` - The main setting for each node group.
  - `name` - The name for each disk attached. Must be unique per machine. **Required**.
  - `device_name` = The block device name for each disk attached. For AWS, due to limitations, this must be in the format `/dev/sd[f-p]` and unique for each disk (more info [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html)). Additionally each block device name must be available on all machines in the target group (e.g. `gitaly-1`, `gitaly-2`, etc...). **Required**.
  - `size` - The size of the disk in GB. __Optional__, default is `100`.
  - `type` - The [type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html) of the disk. __Optional__, default is `gp3`.
  - `iops` - The amount of IOPS to provision for the disk. Only valid for types of `io1`, `io2` or `gp3`. __Optional__, default is `null`.

### Configuring with Ansible

The next step is to configure and mount the disks.

This is done with Ansible and as such will require additional config in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file.

It's worth noting that the Toolkit will always mount disks via UUID to ensure the correct disks are always mounted in the same way through reboots, etc...

The config for this area is given per node type and is passed an array of dictionaries, where each dictionary represents a disk. The config has been designed to be platform agnostic but the actual values may differ, in such a case the difference will be called out clearly. Below is an example of this config with full details after:

**GCP**

```yaml
gitaly_data_disks:
  - { device_name: 'data', mount_dir: '/var/opt/gitlab' }
  - { device_name: 'logs', mount_dir: '/var/log/gitlab' }
```

**AWS**

```yaml
gitaly_data_disks:
  - { device_name: '/dev/sdf', mount_dir: '/var/opt/gitlab' }
  - { device_name: '/dev/sdg', mount_dir: '/var/log/gitlab' }
```

- `*_disks` - The main setting for each node group.
  - `device_name` - The block device name of the disk. Differs depending on Cloud Provider (see below). **Required**.
    - GCP - Device name is the same as its main name. Can be either the short name of the attached disks, e.g. `data`, or the full path, e.g. `/dev/disk/by-id/google-data`.
    - AWS - Must be the block device name you provisioned with Terraform (i.e. `/dev/sd[f-p]`). Can be either the short name of device name, e.g. `sdf`, or the full path, e.g. `/dev/sdf`.
  - `mount_dir` - The path on the machine to mount the disk on.

Note that for AWS, the Toolkit will create symlinks to [match the block device name to the attached NVMe path](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html#identify-nvme-ebs-device).

### Suggested disk mount paths for GitLab

This feature can support mounting a disk on any path in machine groups as desired.

For GitLab we suggest the following mount paths are suggested:

- `/var/opt/gitlab` - Common path for GitLab to store stateful data (e.g. Git Repo data, etc...).
- `/var/log/gitlab` - Common path for GitLab to store its logs.

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

## Container Registry (AWS Hybrid)

Container Registry is enabled by default if you're deploying [Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/#available-reference-architectures) configured with external SSL via GET using AWS cloud provider. Container Registry in that case will run in k8s and use an s3 bucket for storage.

## Disable External IPs (GCP)

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

## System Packages

The Toolkit will install system packages on every node it requires for setting up GitLab.

In addition to this it will configure automated security upgrades and can optionally go further and run full package upgrades if desired. Refer to each section below for more information.

### Automatic Security Upgrades

The Toolkit will install the [Unattended Upgrades](https://help.ubuntu.com/community/AutomaticSecurityUpdates) package on all boxes by default via the [`jnv.unattended-upgrades` Galaxy role](https://galaxy.ansible.com/jnv/unattended-upgrades) to automatically install any security updates for the OS.

The default settings are used in this install which will configure the following:

- Security updates will be installed at least once per day
- The Toolkit will also run the same updates directly whenever it's run
- Automatic reboots are disabled to ensure runtime

The package can be configured further as required by simply adding its config into your Ansible environment config file (`vars.yml`). Refer to the [role's docs](https://galaxy.ansible.com/jnv/unattended-upgrades) for more.

While not recommended, if this behaviour is not desired you can disable this completely by setting the `unattended_upgrades` variable to `false`. Note if setting this after it was previously configured the `unattended-upgrades` package will still need to be purged manually on affected boxes (the Toolkit can't handle this directly as it may interfere with other manual installs of this system package).

### Optional Package Maintenance

The Toolkit can also optionally upgrade all packages and clean up unneeded packages on your nodes on each run. The following settings control this behaviour and can be set in your Ansible environment config file (`vars.yml`) if desired:

- `system_package_upgrades`: Configures the Toolkit to upgrade all packages on nodes. Default is `false`. Can also be set as via the environment variable `SYSTEM_PACKAGE_UPGRADES`.
- `system_package_autoremove`: Configures the Toolkit to autoremove any old or unneeded packages on nodes. Default is `false`. Can also be set as via the environment variable `SYSTEM_PACKAGE_AUTOREMOVE`.
