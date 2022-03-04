# Advanced - Custom Config / Tasks, Data Disks, Advanced Search and more

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [**GitLab Environment Toolkit - Advanced - Custom Config / Tasks, Data Disks, Advanced Search and more**](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)

The Toolkit by default will deploy the latest version of the selected [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/). However, it can also support other advanced setups such as Geo or different component makeups such as Gitaly Sharded.

On this page we'll detail all of the supported advanced setups you can do with the Toolkit. We recommend you only do these setups if you have a good working knowledge of both the Toolkit and what the specific setups involve.

[[_TOC_]]

## Custom Config

The Toolkit allows for you to provide custom GitLab config that will be used when setting up components via Omnibus or Helm charts.

:warning:&nbsp; **This feature must be used with caution**. Any custom config passed will always take precedence and may lead to various unintended consequences or broken environments if not used carefully.

Custom config should only be used in advanced scenarios where you are fully aware of the intended effects or for areas that the Toolkit doesn't support natively due to potential permutations such as:

- Omniauth
- Custom Object Storage
- Email

Custom configs are treated the same as our built in config templates. As such you have access to the same variables for added flexibility.

In this section we detail how to set up custom config for Omnibus and Helm charts components respectively.

### Omnibus

Providing custom config for components deployed via Omnibus is done as follows:

1. Create a [gitlab.rb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template) template file in the correct format with the specific custom settings you wish to apply.
1. By default the Toolkit looks for [Jinja2 template files](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) in the [environment's](environment_configure.md#2-setup-the-environments-inventory-and-config) `files/gitlab_configs` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_configs/<component>.rb.j2`. Save your file in this location with the same name.
    - Files should be saved in Ansible template format - `.j2`.
    - If you wish to store your file in a different location or use a different name the full path that Ansible should use can be set via a variable for each different component e.g. `<component>_custom_config_file`.
    - Available component options: `consul`, `postgres`, `pgbouncer`, `redis`, `redis_cache`, `redis_persistent`, `praefect_postgres`, `praefect`, `gitaly`, `gitlab_rails`, `sidekiq` and `monitor`.

With the above done the file will be picked up by the Toolkit and used when configuring Omnibus.

### Helm

Providing custom config for components deployed via Helm charts in Cloud Native Hybrid environments is done as follows:

1. Create a [GitLab Charts](https://docs.gitlab.com/charts/) yaml template file in the correct format with the specific custom settings you wish to apply
1. By default the Toolkit looks for a [Jinja2 template file](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) named `gitlab_charts.yml.j2` in the [environment's](environment_configure.md#2-setup-the-environments-inventory-and-config) `files/gitlab_configs` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_configs/gitlab_charts.yml.j2`. Save your file in this location with the same name.
    - Files should be saved in Ansible template format - `.j2`.
    - If you wish to store your file in a different location or use a different name the full path that Ansible should use can be set via the `gitlab_charts_custom_config_file` inventory variable.

With the above done the file will be picked up by the Toolkit and used when configuring the Helm charts.

## Custom Tasks

The Toolkit allows you to provide custom Ansible tasks that can be run at several different points in the setup. This allows you to run tasks as required in addition to the main GitLab setup such as installing monitoring tools, performing API calls, etc...

The Toolkit has hooks to allow tasks to be run at the following points during the setup:

- Common - Tasks to run on every VM **before** the component has deployed such as installing general monitoring tools.
- Omnibus - Tasks to run on specific Omnibus VMs **after** the component has been setup via Omnibus such as installing any specific tools for the component.
- Helm - Tasks to run for the Kubernetes Cluster **after** the Charts have been deployed such as deploying additional components into the Cluster.
- Post Configure - Tasks to run against the environment **after** setup from the Ansible runner such as [configuring API settings](https://docs.gitlab.com/ee/api/settings.html).
- Uninstall - Tasks to run as part of the uninstall process such as uninstalling any additional tools.

:warning:&nbsp; **This is an advanced feature and it must be used with caution**. Running custom tasks may lead to various unintended consequences or broken environments if not used carefully.

Setting up common tasks is done in the same manner for each hook as follows:

1. Create a standard Ansible Tasks yaml file with the tasks you wish to run.
    - The file must be in a format that can be run in Ansible's [`include_tasks`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_tasks_module.html) module.
    - You can add the tag `custom_tasks` to your tasks if you wish to run the tasks in isolation.
1. By default the Toolkit looks for each hook's Custom Tasks file(s) in the [environment inventory's](environment_configure.md#2-setup-the-environments-inventory-and-config) `files/gitlab_tasks` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_tasks/<custom_tasks_file>.yml`. This is controlled by the following settings for each:
    - `common_custom_tasks_file` - Full path for the Common tasks file. Defaults to `<inventory_dir>/files/gitlab_tasks/common.yml`.
    - `<component>_custom_tasks_file` - Full path for Omnibus custom tasks files. Where `<component>` should be replaced with the one intended (options below). Defaults to `<inventory_dir>/files/gitlab_tasks/<component>.yml`.
      - Available component options: `consul`, `postgres`, `pgbouncer`, `redis`, `redis_cache`, `redis_persistent`, `praefect_postgres`, `praefect`, `gitaly`, `gitlab_rails`, `sidekiq` and `monitor`.
    - `gitlab_charts_custom_tasks_file` - Full path for the Helm custom tasks file. Defaults to `<inventory_dir>/files/gitlab_tasks/gitlab_charts.yml`.
    - `post_configure_custom_tasks_file` - Full path for the Post Configure custom tasks file. Defaults to `<inventory_dir>/files/gitlab_tasks/post_configure.yml`.
    - `uninstall_custom_tasks_file` - Full path for the Uninstall custom tasks file. Defaults to `<inventory_dir>/files/gitlab_tasks/uninstall.yml`.

Any task within the [Ansible library](https://docs.ansible.com/ansible/2.9/modules/list_of_all_modules.html) can be used for custom tasks, although it's worth noting the following general guidance when writing tasks:

- Any Ansible tasks that aren't core, i.e. available within a standard Ansible install, will need their requirements installed manually before running.
- If there's a requirement to only run Common tasks across all Omnibus VMs only you can do this by setting a `when` condition on the tasks to the Toolkit provided variable `omnibus_node`.
- With the exception of Common, tasks will run after component setup.

## Custom Grafana Dashboards

When using the Toolkit it is possible to pass custom Grafana dashboards during setup to allow Grafana to monitor any metrics required by the user.

By default we recommend storing any custom dashboards alongside your Ansible inventory in `environments/<inventory name>/files/grafana/<collection name>/<dashboard files>`. You can create multiple folders to store different dashboards or store everything in a single folder. If you want to store your custom dashboards in a folder other than `environments/<inventory name>/files/grafana/` then you can set the variable `monitor_custom_dashboards_path` to point to your custom location.

Once the dashboards are in place you can add the `monitor_custom_dashboards` variable into your `vars.yml` file.

```yaml
monitor_custom_dashboards: [{ display_name: 'Sidekiq Dashboards', folder: "my_sidekiq_dashboards" }, { display_name: 'Gitaly Dashboards', folder: "my_gitaly_dashboards" }]
```

- `display_name`: This is how the collection will appear in the Grafana UI and the name of the folder the dashboards will be stored in on the Grafana server.
- `folder`: This is the name of the folder in `monitor_custom_dashboards_path` that holds your collection of dashboards.

To configure custom [Prometheus scape configs](https://docs.gitlab.com/ee/administration/monitoring/prometheus/#adding-custom-scrape-configurations) provide your configuration using `monitor_custom_prometheus_scrape_config` variable.

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
  - `size` - The size of the disk in GB. **Optional**, default is `100`.
  - `type` - The [type](https://cloud.google.com/compute/docs/disks) of the disk. **Optional**, default is `pd-standard`.

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
  - `size` - The size of the disk in GB. **Optional**, default is `100`.
  - `type` - The [type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html) of the disk. **Optional**, default is `gp3`.
  - `iops` - The amount of IOPS to provision for the disk. Only valid for types of `io1`, `io2` or `gp3`. **Optional**, default is `null`.

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

## Custom Servers (On Prem)

While the Toolkit has primarily been designed to support Cloud Providers, there is partial support for configuring Custom Servers (e.g. On prem servers running locally in your network) with Ansible via a [Static Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html).

Please note the following caveats before proceeding:

- Your milage may vary - Due to the sheer potential number of customizations this support is offered on a best effort basis.
- Custom Server setups must follow the [requirements](../README.md#requirements).
- Terraform support is not available. VMs and services must be provisioned separately.
- Object Storage config must be configured via [Custom Config](#custom-config) on any GitLab Rails or Sidekiq nodes as well as Helm Chart for Cloud Native Hybrid environments.
- Data Disks configuration is not supported. These must be configured separately.
- On Cloud Native Hybrid environments the Kubernetes cluster must be configured as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) and `kubeconfig` file created separately.

To configure Custom Servers with Ansible the setup process involves the following:

1. Creating a Static Inventory fine
1. Generating the Facts Cache
1. Configuring the [Environment `vars.yml` file](environment_configure.md#environment-config-varsyml)

Refer to each section below for how to do each:

### Static Config

First an [Ansible Static Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) is required instead of a [Dynamic Inventory](environment_configure.md#configure-dynamic-inventory).

Using the same recommended structure the Static Inventory file should be saved in the inventory folder, e.g. `environments/<env_name>/inventory` alongside the [Environment `vars.yml` file](environment_configure.md#environment-config-varsyml). Several file formats are supported by Ansible but for consistency we'll use `yml` format.

An example of a 10k environment's static inventory file that's Toolkit compatible would be as follows:

```yml
all:
  children:
    consul:
      hosts:
        <CONSUL-1-ADDRESS>:
        <CONSUL-2-ADDRESS>:
        <CONSUL-3-ADDRESS>:
    gitaly:
      hosts:
        <GITALY-1-ADDRESS>:
        <GITALY-2-ADDRESS>:
        <GITALY-3-ADDRESS>:
    gitaly_primary:
      hosts:
        <GITALY-1-ADDRESS>:
    gitaly_secondary:
      hosts:
        <GITALY-2-ADDRESS>:
        <GITALY-3-ADDRESS>:
    gitlab_nfs:
      hosts:
        <GITLAB-NFS-1-ADDRESS>:
    gitlab_rails:
      hosts:
        <GITLAB-RAILS-1-ADDRESS>:
        <GITLAB-RAILS-3-ADDRESS>:
        <GITLAB-RAILS-3-ADDRESS>:
    gitlab_rails_primary:
      hosts:
        <GITLAB-RAILS-1-ADDRESS>:
    gitlab_rails_secondary:
      hosts:
        <GITLAB-RAILS-2-ADDRESS>:
        <GITLAB-RAILS-3-ADDRESS>:
    haproxy_external:
      hosts:
        <HAPROXY-EXTERNAL-1-ADDRESS>:
    haproxy_internal:
      hosts:
        <HAPROXY-INTERNAL-1-ADDRESS>:
    monitor:
      hosts:
        <MONITOR-1-ADDRESS>:
    pgbouncer:
      hosts:
        <PGBOUNCER-1-ADDRESS>:
        <PGBOUNCER-2-ADDRESS>:
        <PGBOUNCER-3-ADDRESS>:
    postgres:
      hosts:
        <POSTGRES-1-ADDRESS>:
        <POSTGRES-2-ADDRESS>:
        <POSTGRES-3-ADDRESS>:
    postgres_primary:
      hosts:
        <POSTGRES-1-ADDRESS>:
    postgres_secondary:
      hosts:
        <POSTGRES-2-ADDRESS>:
        <POSTGRES-3-ADDRESS>:
    praefect:
      hosts:
        <PRAEFECT-1-ADDRESS>:
        <PRAEFECT-2-ADDRESS>:
        <PRAEFECT-3-ADDRESS>:
    praefect_primary:
      hosts:
        <PRAEFECT-1-ADDRESS>:
    praefect_secondary:
      hosts:
        <PRAEFECT-2-ADDRESS>:
        <PRAEFECT-3-ADDRESS>:
    praefect_postgres:
      hosts:
        <PRAEFECT-POSTGRES-1-ADDRESS>:
    praefect_postgres_primary:
      hosts:
        <PRAEFECT-POSTGRES-1-ADDRESS>:
    redis_cache:
      hosts:
        <REDIS-CACHE-1-ADDRESS>:
        <REDIS-CACHE-2-ADDRESS>:
        <REDIS-CACHE-3-ADDRESS>:
    redis_cache_primary:
      hosts:
        <REDIS-CACHE-1-ADDRESS>:
    redis_cache_secondary:
      hosts:
        <REDIS-CACHE-2-ADDRESS>:
        <REDIS-CACHE-3-ADDRESS>:
    redis_persistent:
      hosts:
        <REDIS-PERSISTENT-1-ADDRESS>:
        <REDIS-PERSISTENT-2-ADDRESS>:
        <REDIS-PERSISTENT-3-ADDRESS>:
    redis_persistent_primary:
      hosts:
        <REDIS-PERSISTENT-1-ADDRESS>:
    redis_persistent_secondary:
      hosts:
        <REDIS-PERSISTENT-2-ADDRESS>:
        <REDIS-PERSISTENT-3-ADDRESS>:
    sidekiq:
      hosts:
        <SIDEKIQ-1-ADDRESS>:
        <SIDEKIQ-2-ADDRESS>:
        <SIDEKIQ-3-ADDRESS>:
        <SIDEKIQ-4-ADDRESS>:
    sidekiq_primary:
      hosts:
        <SIDEKIQ-1-ADDRESS>:
    sidekiq_secondary:
      hosts:
        <SIDEKIQ-2-ADDRESS>:
        <SIDEKIQ-3-ADDRESS>:
        <SIDEKIQ-4-ADDRESS>:
    ungrouped:
```

The above file would be tweaked to suit your target environment and each address above should be replaced accordingly. The structure here, including any `*_primary` / `*_secondary` entries should be maintained as the Toolkit requires this.

:information_source:&nbsp; For smaller environments where Redis is combined it would look as follows:

```yml
all:
  children:
    redis:
      hosts:
        <REDIS-1-ADDRESS>:
        <REDIS-2-ADDRESS>:
        <REDIS-3-ADDRESS>:
    redis_primary:
      hosts:
        <REDIS-1-ADDRESS>:
    redis_secondary:
      hosts:
        <REDIS-2-ADDRESS>:
        <REDIS-3-ADDRESS>:
```

### Environment Config

Configuring the environment config `vars.yml` file is [much the same as it would be normally](environment_configure.md#environment-config-varsyml) with the following differences:

- `cloud_provider` **must** be set to `none`. This should be set when running with any static inventory.
- Any Cloud Provider specific variables, such as `gcp_project` should be removed.
- `prefix` can also be removed.

### Facts Cache (Optional)

When running select playbooks, e.g. running a playbook only for `haproxy` - `ansible-playbook -i <inventory> playbooks/haproxy.yml`, some additional preparation is required when using a Static Inventory.

Unlike Dynamic Inventories, in this scenario only facts for the HAProxy hosts and no others are collected. This will cause the play to fail as the Toolkit expects to be able to access facts for all hosts throughout.

:information_source:&nbsp; This _doesn't_ affect playbooks that run on all hosts, such as `all.yml`, as these will gather facts at runtime.

To workaround this limitation a persistent [Fact Cache](https://docs.ansible.com/ansible/latest/plugins/cache.html#cache-plugins) is recommended where all host facts are saved and made available on subsequent runs.

An example would be the [`jsonfile`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/jsonfile_cache.html#ansible-collections-ansible-builtin-jsonfile-cache) cache where all facts are saved to disk. This would only need to be generated once initially and only run again if any of the hosts change.

Refer to the [Ansible docs](https://docs.ansible.com/ansible/latest/plugins/cache.html#cache-plugins) for more info.

## System Packages

The Toolkit will install system packages on every node it requires for setting up GitLab.

In addition to this it will configure automated security upgrades and can optionally go further and run full package upgrades if desired. Refer to each section below for more information.

### Automatic Security Upgrades

The Toolkit will setup automatic security upgrades as a convenience on the target OS via Ansible Galaxy roles as follows:

- Ubuntu - [Unattended Upgrades](https://help.ubuntu.com/community/AutomaticSecurityUpdates) setup via the [`jnv.unattended-upgrades` Galaxy role](https://galaxy.ansible.com/jnv/unattended-upgrades).
- RHEL 8 - [DNF Automatic](https://dnf.readthedocs.io/en/latest/automatic.html) setup via the [`exploide.dnf-automatic` Galaxy role](https://galaxy.ansible.com/exploide/dnf-automatic)

The role(s) configure the following:

- Security updates will be installed at least once per day
- The Toolkit will also run the same updates directly whenever it's run
- Automatic reboots are disabled to ensure runtime

If this behaviour is not desired you can disable this by setting the `system_packages_auto_security_upgrade` variable to `false` (can also be set via environment variable `SYSTEM_PACKAGES_AUTO_SECURITY_UPGRADE`). Note if setting this after it was previously configured the `unattended-upgrades` or `dnf-automatic` package will still need to be purged manually on affected boxes.

### Optional Package Maintenance

The Toolkit can also optionally upgrade all packages and clean up unneeded packages on your nodes on each run. The following settings control this behaviour and can be set in your Ansible environment config file (`vars.yml`) if desired:

- `system_packages_upgrade`: Configures the Toolkit to upgrade all packages on nodes. Default is `false`. Can also be set as via the environment variable `SYSTEM_PACKAGES_UPGRADE`.
- `system_packages_autoremove`: Configures the Toolkit to autoremove any old or unneeded packages on nodes. Default is `false`. Can also be set as via the environment variable `SYSTEM_PACKAGES_AUTOREMOVE`.

## Custom IAM Instance Policies (AWS)

[In AWS you can attach IAM Instance Profiles / Roles to EC2 Instances](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html). These Roles can then contain [Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html) (AKA permissions) that are attached to the instance to allow it to perform actions against AWS APIs, e.g. accessing Object Storage.

The Toolkit uses this functionality in several places to ensure the needed permissions for GitLab are set on the right instances.

As a convenience, you can also pass in additional Policies to either all instances or specific component instances as required (AWS Managed or custom). The Toolkit will manage the Role and attach these policies for you.

Passing in your policies is done in Terraform via the following variables in your `environment.tf` file. Note that for individual component instances the same variable suffix is used throughout, for readability this is defined once only:

- `default_iam_instance_policy_arns` - List of IAM Policy [ARNs](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) to attach on all Instances, for example `["arn:aws:iam::aws:policy/AmazonS3FullAccess"]`. Defaults to `[]`.
- `*_iam_instance_policy_arns` -  List of IAM Policy [ARNs](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) to attach on all Instances. For example if `gitaly_iam_instance_policy_arns` was set to `["arn:aws:iam::aws:policy/AmazonS3FullAccess"]` then this Policy would be applied to all Gitaly instances via a new Role. Defaults to `[]`.

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
