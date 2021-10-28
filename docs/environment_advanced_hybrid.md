# Advanced - Cloud Native Hybrid

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [**GitLab Environment Toolkit - Advanced - Cloud Native Hybrid**](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Custom Config, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)

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

In addition to the above and as [stated earlier in the docs](environment_prep.md) you should have cloud providers tooling installed also, e.g. `gcloud`, to assist with authentication, etc...

## 2. Provisioning the Kubernetes Cluster with Terraform

Provisioning a Cloud Native Hybrid Reference Architecture has been designed to be very similar to a standard one, with native support added to the Toolkit's modules. As such, it only requires some minor config changes in your Environment's config file (`environment.tf`).

Provisioning the required Kubernetes cluster with a cloud provider only requires a few tweaks to your [Environment config file](environment_provision.md#configure-module-settings-environmenttf) (`environment.tf`) - Namely replacing the GitLab Rails and Sidekiq VMs with equivalent k8s Node Pools instead.

By design, the `environment.tf` file is similar to the one used in a [standard environment](environment_provision.md#configure-module-settings-environmenttf) with the following differences:

- `gitlab_rails_x` entries are replaced with `webservice_node_pool_x`. In the charts we run Puma, etc... in Webservice pods.
- `sidekiq_x` entries are replaced with `sidekiq_node_pool_x`
- `supporting_node_pool_x` entries are added for several additional supporting services needed when running components in Helm Charts, e.g. NGINX, etc...
- `haproxy_external_x` entries are removed as the Chart deployment handles external load balancing.

Each node pool setting configures the following. To avoid repetition we'll describe each setting once:

- `*_node_pool_count` - The number of machines to set up for that component's node pool
- `*_node_pool_machine_type` - **GCP only** The [GCP Machine Type](https://cloud.google.com/compute/docs/machine-types) (size) for each machine in the node pool
- `*_node_pool_instance_type` - **AWS only** The [AWS Instance Type](https://aws.amazon.com/ec2/instance-types/) (size) for each machine in the node pool

Below are examples for an `environment.tf` file with all config for each cloud provider based on a [10k Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) with additional Cloud Specific guidances as required:

### Google Cloud Platform (GCP)

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
  redis_persistent_node_count = 3
  redis_persistent_machine_type = "n1-standard-4"
}

output "gitlab_ref_arch_gcp" {
  value = module.gitlab_ref_arch_gcp
}
```

#### Networking (GCP)

As detailed in the earlier [Configuring network setup (GCP)](environment_provision.md#configure-network-setup-gcp) section the same networking options apply for Hybrid environments on GCP.

However there are some additional networking considerations below that you should be aware of before building the environment.

##### Zones

When you optionally configure Zones for GCP resources to be spread across for Kubernetes this will configure a [Multi-Zonal Cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#multi-zonal_clusters).

In this setup however it would deploy the target count of nodes in _every_ zone. So for example if you set up a Node Pool with a Node count of 4 but then also give it 2 Zones to spread across it would proceed to deploy 8 Nodes.

The Toolkit will attempt to manage this for you and try to honor the target node count you have given in config. However if the number of Zones and Node Counts given are different in terms of parity (e.g. when the number of Zones is even and Node Count is odd) it will result in additional nodes being deployed and costing extra. To help with this it's possible to specifically set Zones for the Kubernetes cluster to use as follows:

- `kubernetes_zones` - A list of Zone names inside the target region that any Kubernetes resources should be spread across. This will override what's given in the `zones` variable to allow for additional flexibility. If unset it will follow the former. Default is the same as `zones` (`null`). Optional.

It's recommended that in any environment where multiple Zones are to be used that you match the parity of Node Pool counts, i.e. all Zone and Node Pool counts should be either even or odd.

### Amazon Web Services (AWS)

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key_file = file(var.ssh_public_key_file)

  create_network = true

  # 10k Hybrid - k8s Node Pools
  webservice_node_pool_count = 4
  webservice_node_pool_instance_type = "c5.9xlarge"

  sidekiq_node_pool_count = 4
  sidekiq_node_pool_instance_type = "m5.xlarge"

  supporting_node_pool_count = 3
  supporting_node_pool_instance_type = "m5.xlarge"

  # 10k Hybrid - Compute VMs
  consul_node_count = 3
  consul_instance_type = "c5.large"

  elastic_node_count = 3
  elastic_instance_type = "c5.4xlarge"

  gitaly_node_count = 3
  gitaly_instance_type = "m5.4xlarge"

  praefect_node_count = 3
  praefect_instance_type = "c5.large"

  praefect_postgres_node_count = 1
  praefect_postgres_instance_type = "c5.large"

  gitlab_nfs_node_count = 1
  gitlab_nfs_instance_type = "c5.xlarge"

  haproxy_internal_node_count = 1
  haproxy_internal_instance_type = "c5.large"

  monitor_node_count = 1
  monitor_instance_type = "c5.xlarge"

  pgbouncer_node_count = 3
  pgbouncer_instance_type = "c5.large"

  postgres_node_count = 3
  postgres_instance_type = "m5.2xlarge"

  redis_cache_node_count = 3
  redis_cache_instance_type = "m5.xlarge"
  redis_persistent_node_count = 3
  redis_persistent_instance_type = "m5.xlarge"

  // Add any AWS Auth mappings to this array
  // This defaults to an empty array
  // See `aws_auth_roles` section in documentation for more details
  // aws_auth_roles: [{
  //   rolearn = 'arn:aws:iam::12345:AWS_ROLE_ARN'
  //   kube_username = 'my_kube_username:{{SessionName}}'
  //   kube_groups = ['system:masters']
  // }]
}

output "gitlab_ref_arch_aws" {
  value = module.gitlab_ref_arch_aws
}
```

#### Networking (AWS)

As detailed in the earlier [Configuring network setup (AWS)](environment_provision.md#configure-network-setup-aws) section the same networking options apply for Hybrid environments on AWS.

However there are some additional networking considerations below that you should be aware of before building the environment.

##### Zones

For EKS a [Cluster is required to be spread across at least 2 Availability Zones](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html). How this is handled depends on the network setup you've gone for:

- Default - Will attach to a number of default subnets. This is configurable via the `eks_default_subnet_count` variable that has a default of `2`.
- Create - Will create a number of subnets. This is configurable via the `subnet_pub_count` variable that has a default of `2`.
- Existing - When providing an existing network it's required that it has at least 2 subnets, each on a separate Zone.

#### Deprovisioning

If you ever want to deprovision resources created, with a Cloud Native Hybrid on AWS **you must run [helm uninstall gitlab](https://helm.sh/docs/helm/helm_uninstall/)** before running [terraform destroy](https://www.terraform.io/docs/cli/commands/destroy.html). This ensure all resources are correctly removed.

#### Defining AWS Auth Roles with `aws_auth_roles`

By default EKS automatically grants the IAM entity user or role that creates the cluster `system:masters` permissions in the cluster's RBAC configuration in the control plane. All other IAM users or roles require explicit access. This is defined through the `kube-system/aws-auth` config map. More details are available in the EKS documentation on [Managing users or IAM roles for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html), while full details of the expected format of the `aws-auth` configmap can be found in the [`aws-iam-authenticator` source code repository](https://github.com/kubernetes-sigs/aws-iam-authenticator#full-configuration-format).

```tf
module "gitlab_ref_arch_aws" {
  // other variables...

  aws_auth_roles: [{
    rolearn = 'arn:aws:iam::12345:AWS_ROLE_ARN'        // IAM Role ARN
    kube_username = 'my_kube_username:{{SessionName}}' // Kubernetes RBAC username to map for the Role ARN
    kube_groups = ['system:masters']                   // Kubernetes RBAC groups to map for Role ARN
  }]
}
```

##### Updating `aws-auth` after initialization

If you would like to add additional roles, these can be added through the `aws_auth_roles` variable. When this is set, GET will initialize the `kube-system/aws-auth` config map with the configured rules.

Note that after the initialization, GET will not update this config map. This is because Terraform's default behaviour would overwrite any future changes to the config map. Other EKS processes outside of Terraform may update the `aws-auth` config map, so Terraform would overwrite those changes. As a result, we have disabled updates to the `kube-system/aws-auth` config map after the initial configuration.

If you would like to update the AWS Auth config map after the initial provisioning, use `kubectl edit -n kube-system configmap/aws-auth` to edit the namespace manually. Further details can be found in the AWS EKS Documentation.

## 3. Setting up authentication for the provisioned Kubernetes Cluster

Authenticating with Kubernetes is different compared to other services, and can be [considered a challenge](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#interacting-with-kubernetes) in terms of automation.

In a nutshell authentication must be setup for the `kubectl` command on the machine running the Toolkit. Got the command to be authenticated it requires an entry to be added and selected in its `~/.kubeconfig` file.

The easiest way to do this is via the selected cloud providers tooling after the cluster has been provisioned:

- Google Cloud Platform (GCP) can be setup and selected via the `gcloud get-credentials` command, e.g. `gcloud container clusters get-credentials <CLUSTER NAME> --project <GCP PROJECT NAME> --zone <GCP ZONE NAME>`. Where `<CLUSTER NAME>` will be the same as the `prefix` variable set in Terraform.
- Amazon Web Services (AWS) can be setup and selected via the `aws update-kubeconfig` command, e.g. `aws eks --region <AWS REGION NAME> update-kubeconfig --name <CLUSTER NAME>`. Where `<CLUSTER NAME>` will be the same as the `prefix` variable set in Terraform.

As a convenience, the Toolkit can automatically run these commands for you in its configuration stage when the variable `kubeconfig_setup` is set to `true`. This will be detailed more in the next section.

## 4. Configuring the Helm Charts deployment with Ansible

Like Provisioning with Terraform, configuring the Helm deployment for the Kubernetes cluster only requires a few tweaks to your [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`) - Namely a few extra settings required for Helm.

By design, this file is similar to the one used in a [standard environment](environment_provision.md#configure-module-settings-environmenttf) with the following additional settings:

- `cloud_native_hybrid_environment` - Sets Ansible to know it's configuring a Cloud Native Hybrid Reference Architecture environment. Required.
- `kubeconfig_setup` - When true, will attempt to automatically configure the `.kubeconfig` file entry for the provisioned Kubernetes cluster.
- `external_ip` - **GCP only** External IP the environment will run on. Required along with `external_url` for Cloud Native Hybrid installs.
- `external_url` - This cannot be an IP address in a hybrid environment. You will need a domain or sub-domain to which you or your company owns, to which you can add a DNS record.
- `gcp_zone` - **GCP only** Default Zone name the GCP project is in. Only required for Cloud Native Hybrid installs when `kubeconfig_setup` is set to true.
- `aws_region` - **AWS only** Name of the region where the EKS cluster is located. Only required for Cloud Native Hybrid installs when `kubeconfig_setup` is set to true.
- `aws_allocation_ids` - **AWS only** A comma separated list of allocation IDs to assign to the AWS load balancer.
  - With AWS you **must have an [Elastic IP](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/blob/main/docs/environment_prep.md#4-create-static-external-ip-aws-elastic-ip-allocation) for each subnet being used**, each Elastic IP will have an allocation ID that must be stored in this list.
Below are examples for a `vars.yml` file with all config for each cloud provider based on a [10k Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative):
  
### Google Cloud Platform (GCP)

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
    cloud_native_hybrid_environment: true
    kubeconfig_setup: true

    # Component Settings
    patroni_remove_data_directory_on_rewind_failure: false
    patroni_remove_data_directory_on_diverged_timelines: false

    # Passwords / Secrets
    gitlab_root_password: '<gitlab_root_password>'
    grafana_password: '<grafana_password>'
    postgres_password: '<postgres_password>'
    patroni_password: '<patroni_password>'
    consul_database_password: '<consul_database_password>'
    pgbouncer_password: '<pgbouncer_password>'
    redis_password: '<redis_password>'
    gitaly_token: '<gitaly_token>'
    praefect_external_token: '<praefect_external_token>'
    praefect_internal_token: '<praefect_internal_token>'
    praefect_postgres_password: '<praefect_postgres_password>'
```

### Amazon Web Services (AWS)

```yml
all:
  vars:
    # Ansible Settings
    ansible_user: "<ssh_username>"
    ansible_ssh_private_key_file: "<private_ssh_key_path>"

    # Cloud Settings
    cloud_provider: "aws"
    aws_region: "<aws_region_name>"
    aws_allocation_ids: "<aws_allocation_id1>,<aws_allocation_id2>"

    #General Settings
    prefix: "<environment_prefix>"
    external_url: "<external_url>"
    gitlab_license_file: "<gitlab_license_file_path>"
    cloud_native_hybrid_environment: true
    kubeconfig_setup: true

    # Component Settings
    patroni_remove_data_directory_on_rewind_failure: false
    patroni_remove_data_directory_on_diverged_timelines: false

    # Passwords / Secrets
    gitlab_root_password: '<gitlab_root_password>'
    grafana_password: '<grafana_password>'
    postgres_password: '<postgres_password>'
    patroni_password: '<patroni_password>'
    consul_database_password: '<consul_database_password>'
    pgbouncer_password: '<pgbouncer_password>'
    redis_password: '<redis_password>'
    gitaly_token: '<gitaly_token>'
    praefect_external_token: '<praefect_external_token>'
    praefect_internal_token: '<praefect_internal_token>'
    praefect_postgres_password: '<praefect_postgres_password>'
```

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

Once your config file is in place as desired you can proceed to [configure as normal](environment_configure.md#3-configure-update).

## Geo

More information on setting up Geo within GET can be found in our [Advanced - Geo, Advanced Search and more](environment_advanced.md#geo) documentation.
