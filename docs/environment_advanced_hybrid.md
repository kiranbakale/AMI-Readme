# Advanced - Cloud Native Hybrid

---
<table>
    <tr>
        <td><img src="https://gitlab.com/uploads/-/system/project/avatar/1304532/infrastructure-avatar.png" alt="Under Construction" width="100"/></td>
        <td>The GitLab Environment Toolkit is in **Beta** (`v1.0.0-beta`) and work is currently under way for its main release. We do not recommend using it for production use at this time.<br/><br/>As such, <b>this documentation is still under construction</b> but we aim to have it completed soon.</td>
    </tr>
</table>

---

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Customizations](environment_advanced.md)
  - [**GitLab Environment Toolkit - Advanced - Cloud Native Hybrid**](environment_advanced_hybrid.md)

The Toolkit by default will deploy the latest version of the selected [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/). However, it can also support deploying our alternative [Cloud Native Hybrid Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) where select stateless components are deployed in Kubernetes via our [Helm charts](https://docs.gitlab.com/charts/) instead of static compute VMs. To achieve this the Toolkit can provision the Kubernetes cluster via Terraform and then configure the Helm Chart via Ansible.

While the Toolkit can deploy such an architecture for you it should be noted that this is an advanced setup as running services in Kubernetes is well known to be complex. **This setup is only recommended** if
you have strong working knowledge and experience in Kubernetes. For most users a standard Reference Architecture on static compute VMs typically will suffice, Hybrid architectures should only be used if the specific benefits of Kubernetes are desired.

On this page we'll detail how to deploy a Cloud Native Hybrid Reference Architecture with the Toolkit. **It's worth noting this guide is supplementary to the rest of the docs and it will assume this throughout.**

[[_TOC_]]

## Overview

As detailed in the docs, a Cloud Native Hybrid Reference Architecture is an alternative approach where select stateless components are deployed in Kubernetes via Helm Charts. This primarily includes running the equivalent of GitLab Rails and Sidekiq nodes, named Webservice and Sidekiq respectively, along with some supporting services such as NGINX, Prometheus, etc...

To achieve this with the Toolkit it can provision the Kubernetes cluster via Terraform and then configure the Helm Chart via Ansible.

## 1. Install Kubernetes Tools

For the Toolkit to be able to provision and configure Kubernetes clusters and Helm charts it requires some additional application to be installed on the runner machine as follows:

- `kubectl` - [Install guide](https://kubernetes.io/docs/tasks/tools/#kubectl)
- `helm` - [Install guide](https://helm.sh/docs/intro/install/)

Latest info on version requirements for both tools can be found in the [GitLab Charts docs](https://docs.gitlab.com/charts/installation/tools.html). Also note that both of the above tools will need to be found on the PATH for them to be used by the Toolkit.

In addition to the above and as [stated earlier in the docs](docs/environment_prep.md) you should have cloud providers tooling installed also, e.g. `gcloud`, to assist with authentication, etc...

## 2. Provisioning the Kubernetes Cluster with Terraform

Provisioning a Cloud Native Hybrid Reference Architecture has been designed to be very similar to a normal one, which native support added to the Toolkit's modules. As such, it only requires some different config in your Environment's config file (`environment.tf`).

Like the main provisioning docs there are sections for each support host provider on how to achieve this. Follow the section for your selected provider and then move onto the next step.

### Google Cloud Platform (GCP)

Provisioning the required Kubernetes cluster on Google Kubernetes Engine only requires a few tweaks to your [Environment config file](environment_provision.md#configure-module-settings-environmenttf) (`environment.tf`) - Namely replacing the GitLab Rails and Sidekiq VMs with equivalent k8s Node Pools instead.

Here's an example of a file with all config for a [10k Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) and descriptions below:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  # 10k Hybrid - k8s Node Pools
  webservice_node_pool_count = 4
  webservice_node_pool_machine_type = "n1-highcpu-32"

  sidekiq_node_pool_count = 4
  sidekiq_node_pool_machine_type = "n1-standard-4"

  supporting_node_pool_count = 2
  supporting_node_pool_machine_type = "n1-standard-4"

  object_storage_buckets = ["artifacts", "backups", "dependency-proxy", "lfs", "mr-diffs", "packages", "terraform-state", "uploads"]

  # 10k Hybrid - Compute VMs
  consul_node_count = 3
  consul_machine_type = "n1-highcpu-2"

  elastic_node_count = 3 
  elastic_machine_type = "n1-highcpu-16"

  gitaly_node_count = 3
  gitaly_machine_type = "n1-standard-16"

  praefect_node_count = 3
  praefect_machine_type = "n1-highcpu-2"

  praefect_postgres_node_count = 1
  praefect_postgres_machine_type = "n1-highcpu-2"

  gitlab_nfs_node_count = 1
  gitlab_nfs_machine_type = "n1-highcpu-4"

  haproxy_internal_node_count = 1
  haproxy_internal_machine_type = "n1-highcpu-2"

  monitor_node_count = 1
  monitor_machine_type = "n1-highcpu-4"

  pgbouncer_node_count = 3
  pgbouncer_machine_type = "n1-highcpu-2"

  postgres_node_count = 3
  postgres_machine_type = "n1-standard-8"

  redis_cache_node_count = 3
  redis_cache_machine_type = "n1-standard-4"
  redis_sentinel_cache_node_count = 3
  redis_sentinel_cache_machine_type = "n1-standard-1"
  redis_persistent_node_count = 3
  redis_persistent_machine_type = "n1-standard-4"
  redis_sentinel_persistent_node_count = 3
  redis_sentinel_persistent_machine_type = "n1-standard-1"
}

output "gitlab_ref_arch_gcp" {
  value = module.gitlab_ref_arch_gcp
}
```

By design, this file is similar to the one used in a [normal environment](environment_provision.md#configure-module-settings-environmenttf) with the following differences:

- `gitlab_rails_x` entries are replaced with `webservice_node_pool_x`. In the charts we run Puma, etc... in Webservice pods.
- `sidekiq_x` entries are replaced with `sidekiq_node_pool_x`
- `supporting_node_pool_x` entries are added for several additional supporting services needed when running components in Helm Charts, e.g. NGINX, etc...
- `haproxy_external_x` entries are removed as the Chart deployment handles external load balancing.
- `object_storage_buckets` allows for the creation of separate object storage buckets for each type of data GitLab stores. Each bucket will have the name as configured in this list with the `prefix` being added to the beginning as a prefix. This is required for all Cloud Hybrid installs as given here and will become the default for all installs in the future.

Each node pool setting configures the following. To avoid repetition we'll describe each setting once:

- `*_node_pool_count` - The number of machines to set up for that component's node pool
- `*_node_pool_machine_type` - The [GCP Machine Type](https://cloud.google.com/compute/docs/machine-types) (size) for that each machine in the node pool

Once the above is configured as desired you can proceed to [provision as normal](environment_provision.md#3-provision).

### Amazon Web Services (coming soon)

<img src="https://gitlab.com/uploads/-/system/project/avatar/1304532/infrastructure-avatar.png" alt="Under Construction" width="100"/>

### Azure (coming soon)

<img src="https://gitlab.com/uploads/-/system/project/avatar/1304532/infrastructure-avatar.png" alt="Under Construction" width="100"/>

## 2. Setting up authentication for the provisioned Kubernetes Cluster

Authenticating with Kubernetes is different compared to other services, and can be [considered a challenge](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#interacting-with-kubernetes) in terms of automation.

In a nutshell authentication must be setup for the `kubectl` command on the machine running the Toolkit. Got the command to be authenticated it requires an entry to be added and selected in its `~/.kubeconfig` file.

The easiest way to do this is via the selected cloud providers tooling after the cluster has been provisioned:

- Google Cloud Platform (GCP) - Can be setup and selected via the `gcloud get-credentials` command, e.g. `gcloud container clusters get-credentials <CLUSTER NAME> --project <GCP PROJECT NAME> --zone <GCP ZONE NAME>`. Where `<CLUSTER NAME>` will be the same as the `prefix` variable set in Terraform.

As a convenience, the Toolkit can automatically run this command for you in its configuration stage as well when the variable `kubeconfig_setup` is set to `true`. This will be detailed more in the next section.

## 3. Configuring the Helm Charts deployment with Ansible

Like Provisioning with Terraform, configuring the Helm deployment onto the Kubernetes cluster on Google Kubernetes Engine (as well as configuring the backend compute VMs as normal) only requires a few tweaks to your [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`) - Namely a few extra settings required for Helm and Object Storages.

Here's an example of a file with all config for a [10k Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) and descriptions below:

```yml
all:
  vars:
    # Ansible Settings
    ansible_user: "<ssh_username>"
    ansible_ssh_private_key_file: "<private_ssh_key_path>"

    # Cloud Settings
    cloud_provider: "gcp"
    gcp_project: "<gcp_project_id>"
    gcp_zone: "<gcp_project_zone>"
    gcp_service_account_host_file: "<gcp_service_account_host_file_path>"

    # General Settings
    prefix: "<environment_prefix>"
    external_url: "<external_url>"
    external_ip: "<external_ip>"
    gitlab_license_file: "<gitlab_license_file_path>"
    kubeconfig_setup: true

    # Component Settings
    patroni_remove_data_directory_on_rewind_failure: false
    patroni_remove_data_directory_on_diverged_timelines: false

    # Object Storage Buckets
    gitlab_object_storage_artifacts_bucket: "{{ prefix }}-hybrid-artifacts"
    gitlab_object_storage_backups_bucket: "{{ prefix }}-hybrid-backups"
    gitlab_object_storage_dependency_proxy_bucket: "{{ prefix }}-hybrid-dependency-proxy"
    gitlab_object_storage_external_diffs_bucket: "{{ prefix }}-hybrid-mr-diffs"
    gitlab_object_storage_lfs_bucket: "{{ prefix }}-hybrid-lfs"
    gitlab_object_storage_packages_bucket: "{{ prefix }}-hybrid-packages"
    gitlab_object_storage_terraform_state_bucket: "{{ prefix }}-hybrid-terraform-state"
    gitlab_object_storage_uploads_bucket: "{{ prefix }}-hybrid-uploads"

    # Passwords / Secrets
    gitlab_root_password: '<gitlab_root_password>'
    grafana_password: '<grafana_password>'
    postgres_password: '<postgres_password>'
    consul_database_password: '<consul_database_password>'
    pgbouncer_password: '<pgbouncer_password>'
    redis_password: '<redis_password>'
    gitaly_token: '<gitaly_token>'
    praefect_external_token: '<praefect_external_token>'
    praefect_internal_token: '<praefect_internal_token>'
    praefect_postgres_password: '<praefect_postgres_password>'
```

By design, this file is similar to the one used in a [normal environment](environment_provision.md#configure-module-settings-environmenttf) with the following additional settings:

- `gcp_zone` - Zone name the GCP project is in. Only required for Cloud Native Hybrid installs when `kubeconfig_setup` is set to true.
- `external_ip` - External IP the environment will run on. Required along with `external_url` for Cloud Native Hybrid installs.
- `kubeconfig_setup` - When true, will attempt to automatically configure the `.kubeconfig` file entry for the provisioned Kubernetes cluster.
- `gitlab_object_storage_*_bucket` - The name of the Object Storage bucket for the specific data type. Required for Cloud Native Hybrid installs as given when used in conjunction with the Terraform `object_storage_buckets` setting as detailed above. As with the other setting the above will become the default in the future for all GitLab environments.

### Additional Config Settings

The Toolkit provides several other settings that can customize a Cloud Native Hybrid setup further as follows:

- `gitlab_charts_release_namespace`: Kubernetes namespace the Helm chart will be deployed to. This should only be changed when the namespace is known to be different than the typical default of `default`. Set to `default` by default.
- `gitlab_charts_webservice_requests_memory_gb`: Memory [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Webservice pod in GB. Set to `5` by default.
- `gitlab_charts_webservice_limits_memory_gb`: Memory [limit](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Webservice pod in GB. Set to `5.25` by default.
- `gitlab_charts_webservice_requests_cpu`: CPU [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for Webservice pods in GB. Changing this will affect pod sizing count as well as number of Puma workers and should only be done so for specific reasons. Set to `4` by default.
- `gitlab_charts_webservice_min_replicas_scaler`: Sets the scalar value (`0.0` - `1.0`) to scale minimum pod replicas against the automatically calculated maximum value. Setting this value may affect the performance of the environment and should only be done so for specific reasons. If pod count is overridden directly by `gitlab_charts_webservice_min_replicas` this value will have no effect. Set to `0.75` by default.
- `gitlab_charts_webservice_max_replicas`: Override for the number of max Webservice replicas instead of them being automatically calculated. Setting this value may affect the performance of the environment and should only be done so for specific reasons. Defaults to blank.
- `gitlab_charts_webservice_min_replicas`: Override for the number of min Webservice replicas instead of them being automatically calculated. Setting this value may affect the performance of the environment and should only be done so for specific reasons. Defaults to blank.
- `gitlab_charts_sidekiq_requests_memory_gb`: Memory [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Sidekiq pod in GB. Set to `2` by default.
- `gitlab_charts_sidekiq_limits_memory_gb`: Memory [limit](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Sidekiq pod in GB. Set to `4` by default.
- `gitlab_charts_sidekiq_requests_cpu`: CPU [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for Webservice pods in GB. Changing this will affect pod sizing and should only be done so for specific reasons. Set to `1` by default.
- `gitlab_charts_sidekiq_min_replicas_scaler`: Sets the scalar value (`0.0` - `1.0`) to scale minimum pod replicas against the automatically calculated maximum value. Setting this value may affect the performance of the environment and should only be done so for specific reasons. If pod count is overridden directly by `gitlab_charts_sidekiq_min_replicas` this value will have no effect. Set to `0.75` by default.
- `gitlab_charts_sidekiq_max_replicas`: Override for the number of max Sidekiq replicas instead of them being automatically calculated. Setting this value may affect the performance of the environment and should only be done so for specific reasons. Defaults to blank.
- `gitlab_charts_sidekiq_min_replicas`: Override for the number of min Sidekiq replicas instead of them being automatically calculated. Setting this value may affect the performance of the environment and should only be done so for specific reasons. Defaults to blank.

Once your config file is in place as desired you can proceed to [configure as normal](environment_configure.md#3-configure).

### Amazon Web Services (coming soon)

<img src="https://gitlab.com/uploads/-/system/project/avatar/1304532/infrastructure-avatar.png" alt="Under Construction" width="100"/>

### Azure (coming soon)

<img src="https://gitlab.com/uploads/-/system/project/avatar/1304532/infrastructure-avatar.png" alt="Under Construction" width="100"/>
