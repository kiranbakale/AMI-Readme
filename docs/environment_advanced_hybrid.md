# Advanced - Cloud Native Hybrid

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
- [**GitLab Environment Toolkit - Advanced - Cloud Native Hybrid**](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

The Toolkit by default will deploy the latest version of the selected [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/). However, it can also support deploying our alternative [Cloud Native Hybrid Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) where select stateless components are deployed in Kubernetes via our [Helm charts](https://docs.gitlab.com/charts/) instead of static compute VMs. To achieve this the Toolkit can provision the Kubernetes cluster via Terraform and then configure the Helm Chart via Ansible.

While the Toolkit can deploy such an architecture it should be noted that this is an advanced setup as running services in Kubernetes is well known to be complex. **This setup is only recommended** if
you have strong working knowledge and experience in Kubernetes. For most users a standard Reference Architecture on static compute VMs typically will suffice, Hybrid architectures should only be used if the specific benefits of Kubernetes are desired.

On this page we'll detail how to deploy a Cloud Native Hybrid Reference Architecture with the Toolkit. **It's worth noting this guide is supplementary to the rest of the docs, and it will assume this throughout.**

[[_TOC_]]

## Overview

As detailed in the docs, a Cloud Native Hybrid Reference Architecture is an alternative approach where select stateless components are deployed in Kubernetes via Helm Charts. This primarily includes running the equivalent of GitLab Rails and Sidekiq nodes, named Webservice and Sidekiq respectively, along with some supporting services such as NGINX and Prometheus.

To achieve this with the Toolkit it can provision the Kubernetes cluster via Terraform and then configure the Helm Chart via Ansible.

## 1. Install Kubernetes Tools

For the Toolkit to be able to provision and configure Kubernetes clusters and Helm charts it requires some additional application to be installed on the runner machine as follows:

- `kubectl` - [Install guide](https://kubernetes.io/docs/tasks/tools/#kubectl)
- `helm` - [Install guide](https://helm.sh/docs/intro/install/)
- `gcloud` - [Install guide](https://cloud.google.com/sdk/install). (GCP only)
- `aws cli` - [Install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (AWS only)

Latest info on version requirements for both tools can be found in the [GitLab Charts docs](https://docs.gitlab.com/charts/installation/tools.html). Also note that both of the above tools will need to be found on the PATH for them to be used by the Toolkit.

## 2. Provisioning the Kubernetes Cluster with Terraform

Provisioning a Cloud Native Hybrid Reference Architecture has been designed to be very similar to a standard one, with native support added to the Toolkit's modules. As such, it only requires some minor config changes in your Environment's config file (`environment.tf`).

Provisioning the required Kubernetes cluster with a cloud provider only requires a few tweaks to your [Environment config file](environment_provision.md#configure-module-settings-environmenttf) (`environment.tf`) - Namely replacing the GitLab Rails and Sidekiq VMs with equivalent k8s Node Pools instead.

By design, the `environment.tf` file is similar to the one used in a [standard environment](environment_provision.md#configure-module-settings-environmenttf) with the following differences:

- `gitlab_rails_x` entries are replaced with `webservice_node_pool_x`. In the charts we run Puma and Workhorse in Webservice pods.
- `sidekiq_x` entries are replaced with `sidekiq_node_pool_x`
- `supporting_node_pool_x` entries are added for several additional supporting services needed when running components in Helm Charts, e.g. NGINX.
- `haproxy_external_x` entries are removed as the Chart deployment handles external load balancing.

Each node pool setting configures the following. To avoid repetition we'll describe each setting once:

- `*_node_pool_count` - The number of machines to set up for that component's node pool
  - `*_node_pool_max_count` and `*_node_pool_max_count` are available as alternatives for [Cluster Autoscaling](#cluster-autoscaling).
- `*_node_pool_machine_type` - **GCP only** The [GCP Machine Type](https://cloud.google.com/compute/docs/machine-types) (size) for each machine in the node pool
- `*_node_pool_instance_type` - **AWS only** The [AWS Instance Type](https://aws.amazon.com/ec2/instance-types/) (size) for each machine in the node pool

Below are examples for a `environment.tf` file with all config for each cloud provider based on a [10k Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) with additional Cloud Specific guidances as required:

### Google Cloud Platform (GCP)

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  # 10k Hybrid - k8s Node Pools
  webservice_node_pool_count        = 4
  webservice_node_pool_machine_type = "n1-highcpu-32"

  sidekiq_node_pool_max_count    = 4
  sidekiq_node_pool_machine_type = "n1-standard-4"

  supporting_node_pool_count    = 2
  supporting_node_pool_machine_type = "n1-standard-4"

  # 10k Hybrid - Compute VMs
  consul_node_count   = 3
  consul_machine_type = "n1-highcpu-2"

  elastic_node_count   = 3
  elastic_machine_type = "n1-highcpu-16"

  gitaly_node_count   = 3
  gitaly_machine_type = "n1-standard-16"

  praefect_node_count   = 3
  praefect_machine_type = "n1-highcpu-2"

  praefect_postgres_node_count   = 1
  praefect_postgres_machine_type = "n1-highcpu-2"

  gitlab_nfs_node_count   = 1
  gitlab_nfs_machine_type = "n1-highcpu-4"

  haproxy_internal_node_count   = 1
  haproxy_internal_machine_type = "n1-highcpu-2"

  monitor_node_count   = 1
  monitor_machine_type = "n1-highcpu-4"

  pgbouncer_node_count   = 3
  pgbouncer_machine_type = "n1-highcpu-2"

  postgres_node_count   = 3
  postgres_machine_type = "n1-standard-8"

  redis_cache_node_count        = 3
  redis_cache_machine_type      = "n1-standard-4"
  redis_persistent_node_count   = 3
  redis_persistent_machine_type = "n1-standard-4"
}

output "gitlab_ref_arch_gcp" {
  value = module.gitlab_ref_arch_gcp
}
```

In addition to the above there are some optional settings that can configure the GKE setup as follows:

- `cluster_release_channel` - Set the [GKE release channel](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels), how fast the cluster will be updated to new Kubernetes releases, `STABLE` by default.
- `cluster_enable_workload_identity` - Enable [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity) in the GKE cluster to allow Kubernetes service accounts to act as a user-managed [Google IAM Service Account](https://cloud.google.com/iam/docs/service-accounts#user-managed_service_accounts).

#### Networking (GCP)

As detailed in the earlier [Configuring network setup (GCP)](environment_provision.md#configure-network-setup-gcp) section the same networking options apply for Hybrid environments on GCP.

However, there are some additional networking considerations below that you should be aware of before building the environment.

##### Zones

When you optionally configure Zones for GCP resources to be spread across for Kubernetes this will configure a [Multi-Zonal Cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#multi-zonal_clusters).

In this setup however it would deploy the target count of nodes in _every_ zone. So for example if you set up a Node Pool with a Node count of 4 but then also give it 2 Zones to spread across it would proceed to deploy 8 Nodes.

The Toolkit will attempt to manage this for you and try to honour the target node count you have given in config. However, if the number of Zones and Node Counts given are different in terms of parity (e.g. when the number of Zones is even and Node Count is odd) it will result in additional nodes being deployed and costing extra. To help with this it's possible to specifically set Zones for the Kubernetes cluster to use as follows:

- `kubernetes_zones` - A list of Zone names inside the target region that any Kubernetes resources should be spread across. This will override what's given in the `zones` variable to allow for additional flexibility. If unset it will follow the former. Default is the same as `zones` (`null`). Optional.

It's recommended that in any environment where multiple Zones are to be used that you match the parity of Node Pool counts, i.e. all Zone and Node Pool counts should be either even or odd.

### Amazon Web Services (AWS)

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  create_network = true

  # 10k Hybrid - k8s Node Pools
  webservice_node_pool_min_count     = 2
  webservice_node_pool_max_count     = 6
  webservice_node_pool_instance_type = "c5.9xlarge"

  sidekiq_node_pool_min_count     = 2
  sidekiq_node_pool_max_count     = 6
  sidekiq_node_pool_instance_type = "m5.xlarge"

  supporting_node_pool_min_count     = 2
  supporting_node_pool_max_count     = 4
  supporting_node_pool_instance_type = "m5.xlarge"

  # 10k Hybrid - Compute VMs
  consul_node_count    = 3
  consul_instance_type = "c5.large"

  elastic_node_count    = 3
  elastic_instance_type = "c5.4xlarge"

  gitaly_node_count    = 3
  gitaly_instance_type = "m5.4xlarge"

  praefect_node_count    = 3
  praefect_instance_type = "c5.large"

  praefect_postgres_node_count    = 1
  praefect_postgres_instance_type = "c5.large"

  gitlab_nfs_node_count    = 1
  gitlab_nfs_instance_type = "c5.xlarge"

  haproxy_internal_node_count    = 1
  haproxy_internal_instance_type = "c5.large"

  monitor_node_count    = 1
  monitor_instance_type = "c5.xlarge"

  pgbouncer_node_count    = 3
  pgbouncer_instance_type = "c5.large"

  postgres_node_count    = 3
  postgres_instance_type = "m5.2xlarge"

  redis_cache_node_count         = 3
  redis_cache_instance_type      = "m5.xlarge"
  redis_persistent_node_count    = 3
  redis_persistent_instance_type = "m5.xlarge"
}

output "gitlab_ref_arch_aws" {
  value = module.gitlab_ref_arch_aws
}
```

#### EKS Version and Upgrades

By default, the Toolkit will leave it up to [AWS to manage the Kubernetes version for the cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#version).

However, you can also specify the version as well as control upgrades if desired in Terraform via the following setting in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_version` - The Kubernetes version that the cluster should use if direct control is desired. Increase this value to perform an upgrade directly. Note that when set this also upgrades the Node Group VM's to use the latest AMI version for the cluster (see below for more info). Default is `null`.

##### EKS Component Version Management - Node Group AMI / Addons

When AWS releases a new version of EKS Node Group [AMIs](https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) (OS Version) or Addons for the EKS Cluster version, it doesn't automatically upgrade them. To help with this the Toolkit can manage these upgrades for you.

:information_source:&nbsp; Note that it isn't the same as EKS Cluster version (although a new Cluster version will typically come with new versions for its dependents) as AWS may still release versions of these components for the current Cluster.

It's recommended to manage these versions via the Toolkit to ensure Terraform is aware of them in its state to avoid any issues. As such, there are variables available for each to control what version they run on along with the option to just select whatever is the latest with the following caveats:

- Setting the variables to `latest` will instruct Terraform to retrieve whatever the latest version is for each and upgrade them to it.
- Upgrades will only occur when Terraform is run.
- When using specific versions you should take care to make sure they are compatible with the EKS version. If upgrading the EKS version it's likely that the AMI and addon versions will change as well.

The variables to configure each can be set in Terraform as follows in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_node_group_ami_release_version` - The [AMI release version](https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) to use for the EKS Node Group VMs. Can either be set to a specific version or just `latest` for the most up-to-date version. Defaults to `null`.
- `eks_kube_proxy_version` - Version to use for the [EKS Kube Proxy addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html). Can either be set to a specific version or just `latest` for the most up-to-date version. Defaults to `null`.
- `eks_coredns_version` - Version to use for the [EKS CoreDNS addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html). Can either be set to a specific version or just `latest` for the most up-to-date version. Defaults to `null`.
- `eks_vpc_cni_version` - Version to use for the [EKS VPC CNI addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html). Can either be set to a specific version or just `latest` for the most up-to-date version. Defaults to `null`.
- `eks_ebs_csi_driver_version` - Version to use for the [EBS CSI Driver addon](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html). Can either be set to a specific version or just `latest` for the most up-to-date version. Defaults to `null`.

#### EKS Endpoint Setup

[EKS Clusters have an endpoint](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html) that is used in several ways including internode communication as well as giving access to tools such as the Toolkit and `kubectl`. This endpoint can be configured to be Public, Private or both.

The Toolkit will configure this endpoint to be both Public and Private by default. In this setup the Kubernetes nodes will default to the Private endpoint and keep their connections internal, but there's still an authenticated Public endpoint that the Toolkit uses to configure the cluster as well as be available for any debugging via `kubectl`.

In some cases you may prefer to restrict who can connect to the Public endpoint or disable it entirely. This is configurable in the Toolkit via Terraform with the following settings in your [`environment.tf`](environment_provision.md#configure-module-settings-environmenttf) file:

- `eks_endpoint_public_access` - Controls if the Public endpoint is enabled. Defaults to `true`.
  - :information_source:&nbsp; If this is disabled Ansible needs to be run within the same VPC as the Kubernetes cluster to ensure access.
- `eks_endpoint_public_access_cidr_blocks` - A list of CIDR blocks that are allowed access to the Public endpoint. Defaults to `['0.0.0.0/0']`.

#### EKS Control-Plane Logging

Amazon EKS control plane logging provides audit and diagnostic logs directly from the Amazon EKS control plane to CloudWatch Logs. You can select the exact log types you need by configuring the `eks_enabled_cluster_log_types` variable as an array of string values. Possible values are described in [Amazon EKS control plane logging documentation](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html). Logs are sent as log streams to AWS CloudWatch.

:information_source:&nbsp; Note that there are additional costs to enable this feature. Refer to the above docs for more info.

#### EKS Secrets Envelope Encryption

As an additional security layer for Kubernetes secrets, which are already encrypted on disk automatically, you can optionally enable [envelope encryption of Kubernetes secrets in EKS](https://aws.amazon.com/blogs/containers/using-eks-encryption-provider-support-for-defense-in-depth/) with your own KMS key.

Note however there are several limitations to this feature, such as manually having to encrypt any existing secrets, and it's recommended you review the [documentation](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html#enable-kms) in full.

:exclamation:&nbsp; Enabling this feature is irreversible. Any changes to the key or attempting to disable the feature will require a full rebuild of the cluster.

Enabling the feature is controlled via the following variables:

- `eks_envelope_encryption` - Enables EKS Envelope Encryption. Optional, default is `false`.
- `eks_kms_key_arn` - The ARN for an existing [AWS KMS Key](https://aws.amazon.com/kms/) to be used to encrypt Kubernetes secrets. Note that the key should have the correct policy to allow access for the cluster's IAM role, [refer to the AWS docs for more info](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html#enable-kms). If not provided `default_kms_key_arm` or a Toolkit managed AWS KMS key will be used in that order. Optional, default is `null`.
  - Due to limitations with this feature, it's strongly recommended that you use your own KMS key with the correct policies that align with your security requirements.

#### Networking (AWS)

As detailed in the earlier [Configuring network setup (AWS)](environment_provision.md#configure-network-setup-aws) section the same networking options apply for Hybrid environments on AWS.

However, there are some additional networking considerations below that you should be aware of before building the environment.

##### Zones

For EKS a [Cluster is required to be spread across at least 2 Availability Zones](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html). How this is handled depends on the network setup you've gone for:

- Default - Will attach to a number of default subnets. This is configurable via the `eks_default_subnet_count` variable that has a default of `2`.
- Create - Will create a number of subnets. This is configurable via the `subnet_pub_count` variable that has a default of `2`.
- Existing - When providing an existing network it's required that it has at least 2 subnets, each on a separate Zone.

#### Defining AWS Auth Roles with `aws_auth_roles`

By default, EKS automatically grants the IAM entity user or role that creates the cluster `system:masters` permissions in the cluster's RBAC configuration in the control plane. All other IAM users or roles require explicit access. This is defined through the `kube-system/aws-auth` config map. More details are available in the EKS documentation on [Managing users or IAM roles for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html), while full details of the expected format of the `aws-auth` configmap can be found in the [`aws-iam-authenticator` source code repository](https://github.com/kubernetes-sigs/aws-iam-authenticator#full-configuration-format).

This approach means that the IAM user or role that was used to provisioning GET will have exclusive access to the EKS cluster. No other users or roles will have access.

In order to grant access to the EKS cluster for other IAM user or roles, consult the [EKS documentation](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html). Note that you will need to [configure authentication to the provisioned Kubernetes cluster](#3-setting-up-authentication-for-the-provisioned-kubernetes-cluster) first.

```shell
# Configure kubeconfig access to the EKS cluster
aws eks --region <AWS REGION NAME> update-kubeconfig --name `<CLUSTER NAME>`
# Update the configmap/aws-auth config map with additional users
kubectl edit -n kube-system configmap/aws-auth
```

#### Deprovisioning

If you ever want to deprovision resources created, with a Cloud Native Hybrid on AWS **you must run [helm uninstall gitlab](https://helm.sh/docs/helm/helm_uninstall/)** before running [terraform destroy](https://www.terraform.io/docs/cli/commands/destroy.html). This ensures all resources are correctly removed.

### Cluster Autoscaling

An additional and alternative configuration - Cluster Autoscaling - is available to be provisioned also on both supported Cloud Providers.

[Cluster Autoscaling](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler) is where the node pool VMs are scaled dynamically based on requested pod count.

:information_source:&nbsp; Note this is an advanced setup due to its dynamic nature as it can lead to varying performance and costs.

Enabling this feature on either cloud provider is done via the following settings. To avoid repetition we'll describe each setting once:

- `*_node_pool_max_count` - The maximum number of machines for the component's node pool
- `*_node_pool_min_count` - The minimum number of machines for the component's node pool

The counts to use should be based around the target Reference Architecture, but the actual values should be set based on your expected requirements. As a general guidance we recommend the Reference Architecture's node count as the maximum and at least `2` as the minimum to ensure HA.

:information_source:&nbsp; [Cluster Autoscaler isn't deployed by default in AWS EKS](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html). This either needs to be done manually or can be done with the Toolkit via an additional setting in Ansible - `cloud_native_hybrid_cluster_autoscaler_setup`. Refer to the [Additional Config Settings](#additional-config-settings) for more detail.

## 3. Setting up authentication for the provisioned Kubernetes Cluster

Authenticating with Kubernetes is different compared to other services, and can be [considered a challenge](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#interacting-with-kubernetes) in terms of automation.

In a nutshell authentication must be setup for the `kubectl` command on the machine running the Toolkit. The Toolkit requires the command to be authenticated, and the intended cluster selected as the current context in its `~/.kubeconfig` file.

The easiest way to do this is via the selected cloud providers tooling after the cluster has been provisioned:

- Google Cloud Platform (GCP) can be setup and selected via the `gcloud get-credentials` command, e.g. `gcloud container clusters get-credentials <CLUSTER NAME> --project <GCP PROJECT NAME> --zone <GCP ZONE NAME>`. Where `<CLUSTER NAME>` will be the same as the `prefix` variable set in Terraform.
- Amazon Web Services (AWS) can be setup and selected via the `aws update-kubeconfig` command, e.g. `aws eks --region <AWS REGION NAME> update-kubeconfig --name <CLUSTER NAME>`. Where `<CLUSTER NAME>` will be the same as the `prefix` variable set in Terraform.

As a convenience, the Toolkit can automatically run these commands for you in its configuration stage when the variable `kubeconfig_setup` is set to `true`, but it expects that you have configured authentication beforehand. This will be detailed more in the next section.

## 4. Configuring the Helm Charts deployment with Ansible

Like Provisioning with Terraform, configuring the Helm deployment for the Kubernetes cluster only requires a few tweaks to your [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`) - Namely a few extra settings required for Helm.

By design, this file is similar to the one used in a [standard environment](environment_configure.md#environment-config-varsyml).

First let's detail the general settings that apply to any Cloud Provider:

- `cloud_native_hybrid_environment` - Tells Ansible it's configuring a Cloud Native Hybrid Reference Architecture environment. **Required.**
- `kubeconfig_setup` - When true, will attempt to automatically configure the `.kubeconfig` file entry for the provisioned Kubernetes cluster. **Recommended unless kubeconfig is to be setup separately.**
- `external_url` - A URL for the environment (Note - Not just an IP). You will need to use a `A` type DNS entry (for example `http://gitlab.somecompany.com`). **Required.**
  - :information_source:&nbsp; - On AWS this address should be resolving to _one_ of the Elastic IPs created in the [Create Static External IP - AWS Elastic IP Allocation](environment_prep.md#4-create-static-external-ip-aws-elastic-ip-allocation) step. 
  - Services such as [`nip.io`](https://nip.io/) can provide hostnames without needing to configure DNS but note that this wouldn't be recommended for production environments.

Next are specific Cloud Provider examples that will also detail any specific settings for each provider along with a section on various other additional settings that may be used. 

### Google Cloud Platform (GCP)

For environments using GKE the following additional settings are available:

- `external_ip` - External IP the environment will run on. Required along with `external_url` for Cloud Native Hybrid setups. **Required.**
- `gcp_zone` - Zone name the GCP Kubernetes cluster is in. Only required for Cloud Native Hybrid installs when `kubeconfig_setup` is set to true.

A full `vars.yml` file config example for GKE based on a [10k Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) is as follows:

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

For environments using EKS the following additional settings are available:

- `aws_region` - Name of the region where the EKS cluster is located. Only required for Cloud Native Hybrid installs when `kubeconfig_setup` is set to true.
- `aws_allocation_ids` - A comma separated list of Elastic IP allocation IDs, that will be assigned to the AWS load balancer. **Required.**
  - With AWS, you **must have an [Elastic IP](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_prep.md#4-create-static-external-ip-aws-elastic-ip-allocation) for each subnet being used**. For example using a VPC with 3 subnets will require the creation of 3 Elastic IPs and their individual allocation IDs will need to be stored in this list.
- `cloud_native_hybrid_cluster_autoscaler_setup` - When `true` will deploy the [Cluster Autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html) onto the AWS EKS Kubernetes cluster to enable node autoscaling. Set to `false` by default.

A full `vars.yml` file config example for ELS based on a [10k Cloud Native Hybrid Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) is as follows:

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

- `gitlab_version` - Sets the GitLab version to be installed. The Toolkit finds and selects the equivalent Helm Chart version if configured. This should be set to the full semantic version, e.g. `14.0.0`. If left unset the Toolkit will look to install the latest version. Optional, default is `''`.
- `gitlab_charts_release_namespace`: Kubernetes namespace the Helm chart will be deployed to. This should only be changed when the namespace is known to be different from the typical default of `default`. Set to `default` by default.
- `gitlab_charts_webservice_requests_memory_gb`: Memory [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Webservice pod in GB. Set to `5` by default.
- `gitlab_charts_webservice_limits_memory_gb`: Memory [limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Webservice pod in GB. Set to `5.25` by default.
- `gitlab_charts_webservice_requests_cpu`: CPU [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for Webservice pods in GB. Changing this will affect pod sizing count as well as number of Puma workers and should only be done so for specific reasons. Set to `4` by default.
- `gitlab_charts_webservice_min_replicas_scaler`: Sets the scalar value (`0.0` - `1.0`) to scale minimum pod replicas against the automatically calculated maximum value. Setting this value may affect the performance of the environment and should only be done so for specific reasons. If pod count is overridden directly by `gitlab_charts_webservice_min_replicas` this value will have no effect. Set to `0.75` by default.
- `gitlab_charts_webservice_max_replicas`: Override for the number of max Webservice replicas instead of them being automatically calculated. Setting this value may affect the performance of the environment and should only be done so for specific reasons. Defaults to blank.
- `gitlab_charts_webservice_min_replicas`: Override for the number of min Webservice replicas instead of them being automatically calculated. Setting this value may affect the performance of the environment and should only be done so for specific reasons. Defaults to blank.
- `gitlab_charts_sidekiq_requests_memory_gb`: Memory [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Sidekiq pod in GB. Set to `2` by default.
- `gitlab_charts_sidekiq_limits_memory_gb`: Memory [limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for each Sidekiq pod in GB. Set to `4` by default.
- `gitlab_charts_sidekiq_requests_cpu`: CPU [request](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) for Webservice pods in GB. Changing this will affect pod sizing and should only be done so for specific reasons. Set to `1` by default.
- `gitlab_charts_sidekiq_min_replicas_scaler`: Sets the scalar value (`0.0` - `1.0`) to scale minimum pod replicas against the automatically calculated maximum value. Setting this value may affect the performance of the environment and should only be done so for specific reasons. If pod count is overridden directly by `gitlab_charts_sidekiq_min_replicas` this value will have no effect. Set to `0.75` by default.
- `gitlab_charts_sidekiq_max_replicas`: Override for the number of max Sidekiq replicas instead of them being automatically calculated. Setting this value may affect the performance of the environment and should only be done so for specific reasons. Defaults to blank.
- `gitlab_charts_sidekiq_min_replicas`: Override for the number of min Sidekiq replicas instead of them being automatically calculated. Setting this value may affect the performance of the environment and should only be done so for specific reasons. Defaults to blank.

Once your config file is in place as desired you can proceed to [configure as normal](environment_configure.md#4-configure).

### Custom Secrets (via Custom Tasks)

The Toolkit supports adding additional Kubernetes Secrets for your deployment the Toolkit does provide a hook to do this via a tasks list.

Through this you can provide a custom Ansible tasks file that can run [`kubernetes.core.k8s`](https://github.com/ansible-collections/kubernetes.core/blob/main/docs/kubernetes.core.k8s_module.rst) tasks that in turn can contain standard secrets definitions. For example:

```yml
- name: Configure AWS RDS Internal SSL CA secrets
  kubernetes.core.k8s:
    state: present
    definition:
      kind: Secret
      type: Opaque
      metadata:
        name: "rds-postgres-ca"
        namespace: "{{ gitlab_charts_release_namespace }}" # This should stay the same
      stringData:
        rds_postgres_ca.pem: |
          {{ lookup('file', <local_path_to_postgres_ca_file>) }}
  diff: false
```

Providing custom secrets for the Charts is done as follows:

1. Create a standard Ansible Tasks yaml file with the tasks you wish to run.
    - The file must be in a format that can be run in Ansible's [`include_tasks`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_tasks_module.html) module.
    - You can add the tag `custom_tasks` to your tasks if you wish to run the tasks in isolation.
1. By default, the Toolkit looks for Custom Tasks files in the [environment's](environment_configure.md#2-set-up-the-environments-inventory-and-config) `files/gitlab_tasks` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_tasks/gitlab_charts_secrets.yml`. Save your file in this location with the same name.
    - If you wish to store your file in a different location or use a different name the full path that Ansible should use can be set via a variable for each different component e.g. `gitlab_charts_secrets_tasks_file`.

With the above done, the file will be run before the Helm Charts deployment to add the new secrets.

## Geo

More information on setting up Geo within GET can be found in our [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md) documentation.

## Monitoring

More information on setting up an optional Monitoring stack for Cloud Native Hybrid environments [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md#cloud-native-hybrid) documentation.

## Troubleshooting

Cloud Native Hybrid environments have quite a few moving parts, all of which could cause a failure.

Some common Troubleshooting steps to follow for these setups can be found on the [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md#cloud-native-hybrids) page.
