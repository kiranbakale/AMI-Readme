# Provisioning the environment with Terraform

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [**GitLab Environment Toolkit - Provisioning the environment with Terraform**](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

With [Terraform](https://www.terraform.io/) you can automatically provision machines and associated dependencies on a provider.

The Toolkit provides multiple curated [Terraform Modules](../terraform/modules) that will provision the machines for a GitLab environment as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/).

[[_TOC_]]

## 1. Install Terraform

For the Toolkit we recommend Terraform `v1.1.0` and higher.

Terraform generally works best when all users for an environment are using the same major version due to its State. Improvements have been made that allow for the easier upgrading and downgrading of state however. As such it's recommended that all users sync on the same version of Terraform when working against the same environment and any Terraform upgrades are done in unison.

### Using Terraform inside a Docker container

With Docker the only prerequisite is installation, the [Toolkit's image](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/container_registry/2697240) contains everything else you'll need. The official [Docker installation instructions](https://docs.docker.com/engine/install/) should be followed to correctly install and run Docker.

### Install Terraform using asdf

With the above considerations then we recommend installing Terraform with a Version Manager such as [`asdf`](https://asdf-vm.com/#/) (if supported on your machine(s)).

Installing Terraform with a version manager such as `asdf` has several benefits:

- It's significantly easier to install and switch between multiple versions of Terraform.
- The Terraform version can be specified in a `.tool-versions` file which `asdf` will look for and automatically switch to.
- Being able to switch Terraform versions is particularly useful if you're using the Toolkit to manage multiple environments where versions differ.

Installing Terraform with `asdf` is done as follows (using `v1.1.0` as an example):

1. Install `asdf` as per its [documentation](https://asdf-vm.com/#/core-manage-asdf?id=install)
1. Add the Terraform `asdf` plugin - `asdf plugin add terraform`
1. Install the intended Terraform version - `asdf install terraform 1.1.0`
1. Set that version to be the main on your PATH - `asdf global terraform 1.1.0`

With the above completed Terraform should now be available on your command line. You can check this by running `terraform version`.

## 2. Select Module Source

Before you start setting up the config you should select a Terraform Module source to use.

Terraform can retrieve Modules from various [sources](https://www.terraform.io/language/modules/sources). The Toolkit's Modules are available from Local paths, Git URL or this Project's Terraform Module Registry.

:information_source:&nbsp; These docs assume the Local method is being used but any of these sources can be used as desired.

Below we detail each source and how to configure them:

### Local Path

In this setup you have the Modules saved locally on disk, typically through a Git clone of this repo, and Terraform is configured to source them via an absolute or relative local path.

For example, to configure the `gitlab_ref_arch_gcp` module using a relative path that follows this repo's structure you would configure it follows:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  [...]
}
```

### Git URL

Terraform can also pull the Modules directly from this repo via a [Git URL](https://www.terraform.io/language/modules/sources#generic-git-repository).

For example, to configure the `gitlab_ref_arch_gcp` module to pull from the repo you would configure it follows:

```tf
module "gitlab_ref_arch_gcp" {
  source = "git::https://gitlab.com/gitlab-org/gitlab-environment-toolkit.git//modules/gitlab_ref_arch_gcp"

  [...]
}
```

### Terraform Module Registry

The Toolkit's Modules are also made available via this Project's [Terraform Module Registry](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/infrastructure_registry).

For example, to configure the `gitlab_ref_arch_gcp` module to pull from the registry you would configure it follows:

```tf
module "gitlab_ref_arch_gcp" {
  source = "gitlab.com/gitlab-org/gitlab-environment-toolkit/gitlab//modules/gitlab_ref_arch_gcp"
  version = ">= 2.0.0"

  [...]
}
```

Note the `version` setting here [can be changed as desired to any constraint](https://www.terraform.io/language/expressions/version-constraints#version-constraint-syntax) that's `2.0.0` or greater.

## 3. Setup the Environment's config

As mentioned the Toolkit provides several [Terraform Modules](../terraform/modules) that can be used to provision the environment as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/). While there are several modules provided with the Toolkit most of these are under the hood. For most users only one easy to use `ref_arch` module will need to be configured.

The `ref_arch` modules configure not only the VMs required for the environment but also things such as storage buckets, networking, labels for Ansible to use and more. There's one `ref_arch` module per host provider and for each there are 3 config files to setup:

- `main.tf` - Contains the main Terraform connection settings such as cloud provider, state backend, etc...
- `environment.tf` - `ref_arch` module configuration (machine count, sizes, etc...)
- `variables.tf` - Variable definitions

Each of the above files must be set in the same folder for Terraform to merge. Due to relative path requirements in Terraform we recommend you create these in a unique folder for your environment under the provided [`terraform/environments` folder](../terraform/environments), e.g. `terraform/environments/<env_name>`. These docs will assume this is the case from now on.

In this step there are sections for each supported host provider on how to configure the above files. Follow the section for your selected provider and then move onto the next step.

## Config Examples

[Full config examples are available for select Reference Architectures](../examples). The rest of this section will describe what the config does and how to use it.

### Google Cloud Platform (GCP)

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on GCP is **[`gitlab_ref_arch_gcp`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/tree/main/terraform/modules/gitlab_ref_arch_gcp)**.

In this section we detail all that's needed to configure it.

#### Configure Variables (`variables.tf`)

First we configure the variables needed in the `variables.tf` file as these are used in the other files.

Here's an example of the file with all config and descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
variable "prefix" {
  default = "<environment_prefix>"
}

variable "project" {
  default = "<project_id>"
}

variable "region" {
  default = "<project_region>"
}

variable "zone" {
  default = "<project_zone>"
}

variable "external_ip" {
  default = "<external_ip>"
}
```

- `prefix` - Used to set the names and labels of the VMs in a consistent way. Once set this should not be changed. An example of what this could be is `gitlab-qa-10k`.
- `project` - The [ID](https://support.google.com/googleapi/answer/7014113?hl=en) of the GCP project the environment is to be deployed to.
- `region` - The GCP region of the project, e.g. `us-east1`.
- `zone` - The default GCP zone of the project, e.g. `us-east1-c`.
- `external_ip` - The static external IP the environment will be accessible one. Previously created in the [Create Static External IP - GCP](environment_prep.md#6-create-static-external-ip-gcp) step.

#### Configure Terraform settings (`main.tf`)

The next file to configure is the main Terraform settings file - `main.tf`. In this file will be the main connection details for Terraform to connect to GCP as well as where to store its state.

Here's an example of the file with descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
terraform {
  backend "gcs" {
    bucket  = "<state_gcp_storage_bucket_name>"
    prefix = "<environment_prefix>"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
```

- `terraform` - The main Terraform config block.
  - `backend "gcs"` - The [`gcs` backend](https://www.terraform.io/docs/language/settings/backends/gcs.html) config block.
    - `bucket` - The name of the bucket [previously created](environment_prep.md#5-setup-terraform-state-storage-bucket-gcp-cloud-storage) to store the State.
    - `prefix` - The name of the folder to create in the bucket to store the State.
  - `required_providers` - Config block for the required provider(s) Terraform needs to download and use.
    - `google` - Config block for the GCP provider. Sets where to source the provider and what version to download and use.
- `provider "google"` - Config block for the [Google provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs).
  - `project` - The [ID](https://support.google.com/googleapi/answer/7014113?hl=en) of the GCP project to connect to. Set in `variables.tf`.
  - `region` - The GCP region of the project. Set in `variables.tf`.
  - `zone` - The default GCP zone of the project. Set in `variables.tf`.

#### Configure Module settings (`environment.tf`)

Next to configure is `environment.tf`. This file contains all the config for the `gitlab_ref_arch_gcp` module such as machine counts, machine sizes, external IP, etc...

How you configure this file depends on the size of [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/) you want to deploy. Below we show how a [10k](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) `environment.tf` would be set. If a different size is required all that's required is to tweak the machine counts and sizes to match the desired Reference Architecture as shown in the [docs](https://docs.gitlab.com/ee/administration/reference_architectures/).

Here's an example of the file with all config for a [10k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) and descriptions below:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  # 10k
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

  gitlab_rails_node_count = 3
  gitlab_rails_machine_type = "n1-highcpu-32"

  haproxy_external_node_count = 1
  haproxy_external_machine_type = "n1-highcpu-2"
  haproxy_external_external_ips = [var.external_ip]
  haproxy_internal_node_count = 1
  haproxy_internal_machine_type = "n1-highcpu-2"

  monitor_node_count = 1
  monitor_machine_type = "n1-highcpu-4"

  pgbouncer_node_count = 3
  pgbouncer_machine_type = "n1-highcpu-2"

  postgres_node_count = 3
  postgres_machine_type = "n1-standard-4"

  redis_cache_node_count = 3
  redis_cache_machine_type = "n1-standard-4"
  redis_persistent_node_count = 3
  redis_persistent_machine_type = "n1-standard-4"

  sidekiq_node_count = 4
  sidekiq_machine_type = "n1-standard-4"
}

output "gitlab_ref_arch_gcp" {
  value = module.gitlab_ref_arch_gcp
}
```

- `module "gitlab_ref_arch_gcp"` - Module config block with name.
  - `source` - The relative path to the `gitlab_ref_arch_gcp` module. We assume you're creating config in the `terraform/environments/` folder here but if you're in a different location this setting must be updated to the correct path.
  - `prefix` - The name prefix of the project. Set in `variables.tf`.
  - `project` - The [ID](https://support.google.com/googleapi/answer/7014113?hl=en) of the GCP project to connect to. Set in `variables.tf`.

Next in the file are the various machine settings, separated the same as the Reference Architectures. To avoid repetition we'll describe each setting once:

- `*_node_count` - The number of machines to set up for that component
- `*_machine_type` - The [GCP Machine Type](https://cloud.google.com/compute/docs/machine-types) (size) for that component
- `haproxy_external_external_ips` - Set the external HAProxy load balancer to assume the external IP set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP.

In addition to the above, the following optional settings are also available:

- `machine_image` - The [GCP machine image name](https://cloud.google.com/compute/docs/images/os-details) to use for the VMs. Ubuntu 18.04+ and RHEL 8 images are supported at this time. Defaults to `ubuntu-1804-lts`
- `machine_secure_boot` - Controls whether [Secure Boot](https://cloud.google.com/security/shielded-cloud/shielded-vm#secure-boot) is enabled on the VMs. Can only be enabled for OS Images that support the `Shielded VM` feature. Defaults to `false`.
- `object_storage_location` - The [GCS Location](https://cloud.google.com/storage/docs/locations) buckets are created in. Refer to the [Object Storage Location (GCP)](#object-storage-location-gcp) below for more info.
- `object_storage_force_destroy` - Controls whether Terraform can delete all objects (including any locked objects) from the bucket so that the bucket can be destroyed without error. Consider setting this value to `false` for production systems. Defaults to `true`.
- `object_storage_labels` - Labels to apply to object storage buckets.
- `object_storage_prefix` - An optional prefix to use for the bucket names instead of `prefix`. Can be used to ensure unique names for buckets. :warning:&nbsp; **Changing this setting on an existing environment must be treated with the utmost caution as it will destroy the previous bucket(s) and lead to data loss**.
- `allow_stopping_for_update` - Controls whether Terraform can restart VMs when making changes if required. Should only be disabled for additional resilience. Defaults to `true`.

:information_source:&nbsp; Redis prefixes depend on the target Reference Architecture - set `redis_*` for combined Redis, `redis_cache_*` and `redis_persistent_*` for separated Redis setup.

:information_source:&nbsp; The Toolkit currently **requires** a NFS node to distribute select config.

##### Configure Machine OS Image (GCP)

By default the Toolkit will configure machines using Ubuntu 18.04.

However this can be changed via the `machine_image` in the [module's environment config file](#configure-module-settings-environmenttf) to the [machine image name as given by GCP](https://cloud.google.com/compute/docs/images/os-details), e.g. `ubuntu-1804-lts` or `rhel-8`.

:information_source:&nbsp; The Toolkit currently supports Ubuntu 18.04+ and RHEL 8 images at this time.

:warning:&nbsp; After deployment, this value shouldn't be changed as this would trigger a full rebuild (as it's treated as the base disk) and lead to data loss. Upgrading the OS should be done directly on the machines via their standard process.

##### Object Storage Location (GCP)

The [Terraform Google provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs) doesn't automatically create buckets in the same region it's configured with. [This is due to the various location permutations available in GCP that don't directly map to regions](https://cloud.google.com/storage/docs/locations).

Depending on the provider's version it will typically create buckets in the `US` multi-region by default. The Toolkit follows this design.

To ensure good performance you should select a [location](https://cloud.google.com/storage/docs/locations) that is close to the region you've selected for the environment. We recommend either picking a [Multi-Region](https://cloud.google.com/storage/docs/locations#location-mr) if it's available for built in HA or [Region](https://cloud.google.com/storage/docs/locations#location-r) if the former isn't available. However any location can be chosen as desired based on your requirements.

:warning:&nbsp; **{- Changing this setting on an existing environment must be treated with the utmost caution as it will destroy the previous bucket(s) and lead to data loss-}**+

##### Object Storage versioning (GCP)

The Toolkit can enable [versioning in Google Cloud Storage buckets](https://cloud.google.com/storage/docs/object-versioning) within GCP by setting the `object_storage_versioning` flag to `true`. This will enable the storing of multiple variants of an object in the same bucket. As this can lead to increased storage costs it is recommended to set up an [Object Lifecycle Management](https://cloud.google.com/storage/docs/lifecycle) to remove older versions of stored objects.

##### Configure Network Setup (GCP)

By default the toolkit sets up the infrastructure on the default network stack as provided by GCP. However, it can also support other advanced setups such as creating a new network or using an existing one. To learn more refer to [Configure network setup (GCP)](environment_advanced_network.md#configure-network-setup-gcp).

##### Configure Network Zones (GCP)

With GCP you can spread optionally spread resources across multiple [Availability Zones](https://cloud.google.com/compute/docs/regions-zones) in the selected region, overriding the default Zone configured in `variables.tf`. By doing this it adds additional resilience for the environment in the case a Zone ever went down.

:information_source:&nbsp; Cross Zone networking does have an additional cost. Refer to the [GCP pricing page](https://cloud.google.com/vpc/network-pricing) for more info.

No matter what Network design above you have selected, spreading resources across Zones can also be applied in the [module's environment config file](#configure-module-settings-environmenttf) with the following variables:

- `zones` - A list of Zone names that resources should be spread across. Default is `null`. Optional.

An example of your environment config file then would look like when using the Default network in the `us-east1` region:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  zones = ["us-east1-b", "us-east1-c", "us-east1-d"]

  [...]
}
```

Note that the default zone configured in `variables.tf` is still required in this setup as a backup for other resources.

#### Configure Authentication (GCP)

Finally the last thing to configure is authentication. This is required so Terraform can access GCP (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication) and [backend](https://www.terraform.io/docs/language/settings/backends/gcs.html#configuration-variables), you can select any method that is desired.

All of the methods given involve the Service Account file you generated previously. We've found the authentication methods that work best with the Toolkit in terms of ease of use are as follows:

- `GOOGLE_CREDENTIALS` environment variable - This environment variable is picked up by both the provider and backend, meaning it only needs to be set once. It's particularly useful with CI pipelines. The variable should be set to the path of the Service Account file.
- `gcloud` login - Authentication can also occur automatically through the [`gcloud`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default) command line tool. Make sure the user that's logged in has access to the Project along with the `editor` role attached.

### Amazon Web Services (AWS)

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on AWS is **[`gitlab_ref_arch_aws`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/tree/main/terraform/modules/gitlab_ref_arch_aws)**.

In this section we detail all that's needed to configure it.

#### Configure Variables (`variables.tf`)

First we configure the variables needed in the `variables.tf` file as these are used in the other files.

Here's an example of the file with all config and descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
variable "prefix" {
  default = "<environment_prefix>"
}

variable "region" {
  default = "<region>"
}

variable "ssh_public_key_file" {
  default = "<ssh_public_key_file>"
}

variable "external_ip_allocation" {
  default = "<external_ip_allocation>"
}
```

- `prefix` - Used to set the names and labels of the VMs in a consistent way. Once set this should not be changed. An example of what this could be is `gitlab-qa-10k`.
- `region` - The AWS region of the project.
- `ssh_public_key_file` - Path to the public SSH key file. Previously created in the [Setup SSH Authentication - AWS](environment_prep.md#2-setup-ssh-authentication-aws) step.
- `external_ip_allocation` - The Allocation ID for the static external IP the environment will be accessible on. Previously created in the [Create Static External IP - AWS Elastic IP Allocation](environment_prep.md#4-create-static-external-ip-aws-elastic-ip-allocation) step.

:information_source:&nbsp; The prefix must be unique to this environment and cannot match any other environments stored within your Cloud Provider. When provisioning your environment, if you get errors due to naming conflicts then the most likely cause will be due to other resources having the same prefix as in some cases names are global on Cloud Providers.

#### Configure Terraform settings (`main.tf`)

The next file to configure is the main Terraform settings file - `main.tf`. In this file will be the main connection details for Terraform to connect to AWS as well as where to store its state.

Here's an example of the file with descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
terraform {
  backend "s3" {
    bucket = "<state_aws_storage_bucket_name>"
    key    = "<state_file_path_and_name>"
    region = "<state_aws_storage_bucket_region>"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}
```

- `terraform` - The main Terraform config block.
  - `backend "s3"` - The [`s3` backend](https://www.terraform.io/docs/language/settings/backends/s3.html) config block.
    - `bucket` - The name of the bucket [previously created](environment_prep.md#3-setup-terraform-state-storage-s3) to store the State.
    - `key` - The file path and name to store the state in (example: `path/to/my/key`- [must not start with '/'](https://github.com/hashicorp/terraform/blob/main/internal/backend/remote-state/s3/backend.go#L30-L41)).
    - `region` - The AWS region of the bucket.
  - `required_providers` - Config block for the required provider(s) Terraform needs to download and use.
    - `aws` - Config block for the AWS provider. Sets where to source the provider and what version to download and use.
- `provider "aws"` - Config block for the [AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).
  - `region` - The AWS region of the project. Set in `variables.tf`.

#### Configure Module settings (`environment.tf`)

Next to configure is `environment.tf`. This file contains all the config for the `gitlab_ref_arch_aws` module such as instance counts, instance sizes, external IP, etc...

How you configure this file depends on the size of [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/) you want to deploy. Below we show how a [10k](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) `environment.tf` would be set. If a different size is required all that's required is to tweak the machine counts and sizes to match the desired Reference Architecture as shown in the [docs](https://docs.gitlab.com/ee/administration/reference_architectures/).

Here's an example of the file with all config for a [10k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) and descriptions below:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  # 10k
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

  gitlab_rails_node_count = 3
  gitlab_rails_instance_type = "c5.9xlarge"

  haproxy_external_node_count = 1
  haproxy_external_instance_type = "c5.large"
  haproxy_external_elastic_ip_allocation_ids = [var.external_ip_allocation]
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

  sidekiq_node_count = 4
  sidekiq_instance_type = "m5.xlarge"
}

output "gitlab_ref_arch_aws" {
  value = module.gitlab_ref_arch_aws
}
```

- `module "gitlab_ref_arch_aws"` - Module config block with name.
  - `source` - The relative path to the `gitlab_ref_arch_aws` module. We assume you're creating config in the `terraform/environments/` folder here but if you're in a different location this setting must be updated to the correct path.
  - `prefix` - The name prefix of the project. Set in `variables.tf`.
  - `ssh_public_key` - The SSH key value, typically read from a SSH key file set as `ssh_public_key_file` in `variables.tf`.
  - `object_storage_force_destroy` - Controls whether Terraform can delete all objects (including any locked objects) from the bucket so that the bucket can be destroyed without error. Consider setting this value to `false` for production systems. Defaults to `true`.
  - `object_storage_versioning` - Controls whether Object Storage versioning is enabled for the buckets. Refer to the [Object Storage versioning (AWS)](#object-storage-versioning-aws) below for more info.
  - `object_storage_prefix` - An optional prefix to use for the bucket names instead of `prefix`. Can be used to ensure unique names for buckets. :warning:&nbsp; **Changing this setting on an existing environment must be treated with the utmost caution as it will destroy the previous bucket(s) and lead to data loss**.

Next in the file are the various machine settings, separated the same as the Reference Architectures. To avoid repetition we'll describe each setting once:

- `*_node_count` - The number of machines to set up for that component
- `*_instance_type` - The [AWS Instance Type Machine Type](https://aws.amazon.com/ec2/instance-types/) (size) for that component
- `*_disk_delete_on_termination` - (Optional) Whether the root volume should be destroyed on instance termination. Defaults to true
- `haproxy_external_elastic_ip_allocation_ids` - Set the external HAProxy load balancer to assume the external IP allocation ID set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP allocation ID.

:information_source:&nbsp; Redis prefixes depend on the target Reference Architecture - set `redis_*` for combined Redis, `redis_cache_*` and `redis_persistent_*` for separated Redis setup.

##### Configure Machine OS Image (AWS)

By default the Toolkit will configure machines using the latest Ubuntu 18.04 AMI.

However this can be changed via the `ami_id` setting in the [module's environment config file](#configure-module-settings-environmenttf). [Refer to the AWS docs on how to find the specific AMI ID you require](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html).

:information_source:&nbsp; The Toolkit currently supports Ubuntu 18.04+, RHEL 8 and Amazon Linux 2 images at this time.

:warning:&nbsp; After deployment, this value shouldn't be changed as this would trigger a full rebuild (as it's treated as the base disk) and lead to data loss. Upgrading the OS should be done directly on the machines via their standard process.

##### Object Storage versioning (AWS)

The Toolkit can enable [versioning in S3 buckets](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html) within AWS by setting the `object_storage_versioning` flag to `true`. This will enable the storing of multiple variants of an object in the same bucket. As this can lead to increased storage costs it is recommended to setup a [storage lifecycle configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html) to remove older versions of stored objects.

##### Configure network setup (AWS)

By default the toolkit sets up the infrastructure on the default network stack as provided by AWS. However, it can also support other advanced setups such as creating a new network or using an existing one. To learn more refer to [Configure network setup (AWS)](environment_advanced_network.md#configure-network-setup-aws).

##### Storage Encryption (AWS)

By default AWS doesn't encrypt storages such as disks or object storage buckets.

The Toolkit will aim to encrypt these by default where possible utilizing the built in AWS [default KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#kms_keys) or creating ones where that isn't possible. It also allows for you to pass in your own KMS key(s) as desired in a flexible manner.

An overview of how the Toolkit handles this encryption is as follows:

- By default it will aim to encrypt all storages and services with AWS managed KMS keys.
  - If an AWS managed KMS key isn't available for that particular service the Toolkit will create one.
- A custom KMS key ARN (one that's available in AWS KMS) can be configured for use instead for all storages and services.
- Additionally it's possible to pass custom KMS key(s) for individual storages and services as desired.

The above is also the precedence of how the Toolkit will handle this. For example if you provided a custom KMS key for a specific storage only the Toolkit will use it as configured but then use the default key for the rest.

There are several variables available to configure in the [module's environment config file](#configure-module-settings-environmenttf) for the encryption strategy desired. To cover the scenarios above we'll split each into its own section and how to configure blow.

:warning:&nbsp; **{- Changing encryption settings setup on an existing environment must be treated with the utmost caution-}**. **Doing so is typically considered a significant change and will trigger the recreation of the affected storages and services leading to data loss**.

###### Default Encryption

Encryption is enabled by default for all storages and services using either AWS managed or created KMS keys.

:information_source:&nbsp; For backwards compatibility, encryption of Root Block Device disks can be controlled via the `default_disk_encrypt` setting. It's also possible to specify this setting for each component, e.g. `gitaly_disk_encrypt`. **{- Changing these settings on an existing environment will trigger the recreation of all nodes and will lead to data loss-}**. Snapshots should be taken before doing this and then restored onto the new encrypted disks, refer to the [AWS docs for more info](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html#encrypt-unencrypted).

###### Encryption with user provided KMS keys

Encryption for all storage and services with your own KMS keys is supported by the Toolkit.

Note that these keys must be [available in AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html) beforehand. Once available, you can configure them to be used with the following variables be configured with the following variables. Note that for individual storages or services the same variable suffix is used throughout, for readability this is defined once only:

- `default_kms_key_arn` - The AWS KMS key ARN to use for all storages and services unless configured otherwise. Defaults to `null`.
  - This setting is also used for [Cloud Native Hybrid EKS clusters](environment_advanced_hybrid.md) and / or any [cloud services](environment_advanced_services.md) and Cloud Native Hybrid EKS clusters.
- `*_kms_key_arn` - The AWS KMS key ARN to be used for a specific storage. For example `gitaly_disk_kms_key_arn` will configure a specific key for all its disk(s) and `object_storage_kms_key_arn` configures a key for all buckets.

:information_source:&nbsp; Note that the key used for `object_storage_kms_key_arn` needs to have the [correct policy document applied](https://aws.amazon.com/premiumsupport/knowledge-center/s3-bucket-access-default-encryption/) to allow for IAM authentication by GitLab. The policy document should allow access to the IAM role created by the Toolkit for S3 access.

#### Configure Authentication (AWS)

Finally the last thing to configure is authentication. This is required so Terraform can access AWS (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) and [backend](https://www.terraform.io/docs/language/settings/backends/s3.html#configuration), you can select any method that is desired.

All of the methods given involve the AWS Access Key you generated previously. We've found that the easiest and secure way to do this is with the official [environment variables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables):

- `AWS_ACCESS_KEY_ID` - Set to the AWS Access Key.
- `AWS_SECRET_ACCESS_KEY` - Set to the AWS Secret Key.

Once the two variables are either set locally or in your CI pipeline Terraform will be able to fully authenticate for both the provider and backend.

### Azure

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on Azure is **[`gitlab_ref_arch_azure`](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/tree/main/terraform/modules/gitlab_ref_arch_azure)**.

In this section we detail all that's needed to configure it.

#### Configure Variables (`variables.tf`)

First we configure the variables needed in the `variables.tf` file as these are used in the other files.

Here's an example of the file with all config and descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
variable "prefix" {
  default = "<environment_prefix>"
}

variable "resource_group_name" {
  default = "<resource_group_name>"
}

variable "location" {
  default = "<location>"
}

variable "vm_admin_username" {
  default = "<vm_admin_username>"
}

variable "ssh_public_key_file_path" {
  default = "<ssh_public_key_file_path>"
}

variable "storage_account_name" {
  default = "<storage_account_name>"
}

variable "external_ip_name" {
  default = "<external_ip_name>"
}

```

- `prefix` - Used to set the names and labels of the VMs in a consistent way. Once set this should not be changed. An example of what this could be is `gitlab-qa-10k`.
- `resource_group_name` - The name of the resource group previously created in the [Create Azure Resource Group](environment_prep.md#1-create-azure-resource-group) step.
- `location` - The Azure location of the resource group.
- `vm_admin_username` - The username of the local administrator that will be used for the virtual machines. Previously created in the [Setup SSH Authentication - Azure](environment_prep.md#3-setup-ssh-authentication-azure) step.
- `ssh_public_key_file_path` - Path to the public SSH key file. Previously created in the [Setup SSH Authentication - Azure](environment_prep.md#3-setup-ssh-authentication-azure) step.
- `storage_account_name` - The name of the storage account previously created in the [Setup Terraform State Storage - Azure Blob Storage](environment_prep.md#4-setup-terraform-state-storage-azure-blob-storage) step.
- `external_ip_name` - The name of the static external IP the environment will be accessible one. Previously created in the [Create Static External IP - Azure](environment_prep.md#5-create-static-external-ip-azure) step.

#### Configure Terraform settings (`main.tf`)

The next file to configure is the main Terraform settings file - `main.tf`. In this file will be the main connection details for Terraform to connect to AWS as well as where to store its state.

Here's an example of the file with descriptions below. Items in `<>` brackets need to be replaced with your config:

```tf
terraform {
  backend "azurerm" {
    resource_group_name  = "<resource_group_name>"
    storage_account_name = "<storage_account_name>"
    container_name       = "<state_azure_storage_container_name>"
    key                  = "<state_file_path_and_name>"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
```

- `terraform` - The main Terraform config block.
  - `backend "azurerm"` - The [`azurerm` backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html) config block.
    - `resource_group_name` - The name of the resource group previously created in the [Create Azure Resource Group](environment_prep.md#1-create-azure-resource-group) step.
    - `storage_account_name` - The name of the storage account previously created in the [Setup Terraform State Storage - Azure Blob Storage](environment_prep.md#4-setup-terraform-state-storage-azure-blob-storage) step.
    - `container_name` - The name of the container [previously created](environment_prep.md#4-setup-terraform-state-storage-azure-blob-storage) to store the State.
    - `key` - The name of the Blob(file) used to store Terraform's State file inside the Storage Container.
  - `required_providers` - Config block for the required provider(s) Terraform needs to download and use.
    - `azurerm` - Config block for the Azure provider. Sets where to source the provider and what version to download and use.
- `provider "azurerm"` - Config block for the [Azure provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs).
  - `features` - Used to [customize the behavior](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#features) of certain Azure Provider resources.

#### Configure Module settings (`environment.tf`)

Next to configure is `environment.tf`. This file contains all the config for the `gitlab_ref_arch_azure` module such as instance counts, instance sizes, external IP, etc...

How you configure this file depends on the size of [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/) you want to deploy. Below we show how a [10k](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) `environment.tf` would be set. If a different size is required all that's required is to tweak the machine counts and sizes to match the desired Reference Architecture as shown in the [docs](https://docs.gitlab.com/ee/administration/reference_architectures/).

Here's an example of the file with all config for a [10k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) and descriptions below:

```tf
module "gitlab_ref_arch_azure" {
  source = "../../modules/gitlab_ref_arch_azure"

  prefix = var.prefix
  resource_group_name = var.resource_group_name
  location = var.location
  storage_account_name = var.storage_account_name
  vm_admin_username = var.vm_admin_username
  ssh_public_key = file(var.ssh_public_key_file_path)
  external_ip_type = "Standard"

  # 10k
  consul_node_count = 3
  consul_size = "Standard_F2s_v2"

  elastic_node_count = 3
  elastic_size = "Standard_F16s_v2"

  gitaly_node_count = 3
  gitaly_size = "Standard_D16s_v3"

  praefect_node_count = 3
  praefect_size = "Standard_F2s_v2"

  praefect_postgres_node_count = 1
  praefect_postgres_size = "Standard_F2s_v2"

  gitlab_nfs_node_count = 1
  gitlab_nfs_size = "Standard_F4s_v2"

  gitlab_rails_node_count = 3
  gitlab_rails_size = "Standard_F32s_v2"

  haproxy_external_node_count = 1
  haproxy_external_size = "Standard_F2s_v2"
  haproxy_external_external_ip_names = [var.external_ip_name]
  haproxy_internal_node_count = 1
  haproxy_internal_size = "Standard_F2s_v2"

  monitor_node_count = 1
  monitor_size = "Standard_F4s_v2"

  pgbouncer_node_count = 3
  pgbouncer_size = "Standard_F2s_v2"

  postgres_node_count = 3
  postgres_size = "Standard_D8s_v3"

  redis_cache_node_count = 3
  redis_cache_size = "Standard_D4s_v3"
  redis_persistent_node_count = 3
  redis_persistent_size = "Standard_D4s_v3"

  sidekiq_node_count = 4
  sidekiq_size = "Standard_D4s_v3"
}

output "gitlab_ref_arch_azure" {
  value = module.gitlab_ref_arch_azure
}
```

- `module "gitlab_ref_arch_azure"` - Module config block with name.
  - `source` - The relative path to the `gitlab_ref_arch_azure` module. We assume you're creating config in the `terraform/environments/` folder here but if you're in a different location this setting must be updated to the correct path.
  - `prefix` - The name prefix of the project. Set in `variables.tf`.
  - `resource_group_name` - The name of the resource group. Set in `variables.tf`.
  - `location` - The location of the resource group. Set in `variables.tf`.
  - `storage_account_name` - The name of the storage account. Set in `variables.tf`.
  - `vm_admin_username` - The username of the administrator for the virtual machines. Set in `variables.tf`.
  - `ssh_public_key` - The SSH key value, typically read from a SSH key file set as `ssh_public_key_file` in `variables.tf`.
  - `external_ip_type` - [The type of Public IP](https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses) that will be created for each VM. Can be either `Standard` (recommended) or `Basic`. Default is `Basic` for backwards compatability.
  - `object_storage_prefix` - An optional prefix to use for the bucket names instead of `prefix`. Can be used to ensure unique names for buckets. :warning:&nbsp; **Changing this setting on an existing environment must be treated with the utmost caution as it will destroy the previous bucket(s) and lead to data loss**.

Next in the file are the various machine settings, separated the same as the Reference Architectures. To avoid repetition we'll describe each setting once:

- `*_node_count` - The number of machines to set up for that component
- `*_size` - The [Azure Machine Size](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes) for that component
- `haproxy_external_external_ip_names` - Set the external HAProxy load balancer to assume the external IP name set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP name.

:information_source:&nbsp; Redis prefixes depend on the target Reference Architecture - set `redis_*` for combined Redis, `redis_cache_*` and `redis_persistent_*` for separated Redis setup.

##### Configure Machine OS Image (Azure)

By default the Toolkit will configure machines using the latest Ubuntu 18.04 AMI.

However this can be changed via the `source_image_reference` dictionary setting in the [module's environment config file](#configure-module-settings-environmenttf). [Refer to the Azure docs on how to find the specific source image details you require](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage).

When the image has been selected the setting will need the `publisher`, `offer`, `sku` and `version` fields set. For example:

```tf
module "gitlab_ref_arch_azure" {
  source = "../../modules/gitlab_ref_arch_azure"

  source_image_reference = {
    "publisher" = "Canonical"
    "offer"     = "UbuntuServer"
    "sku"       = "18.04-LTS"
    "version"   = "latest"
  }

  [...]
}
```

:information_source:&nbsp; The Toolkit currently supports Ubuntu 18.04+ and RHEL 8 images at this time.

:warning:&nbsp; After deployment, this value shouldn't be changed as this would trigger a full rebuild (as it's treated as the base disk) and lead to data loss. Upgrading the OS should be done directly on the machines via their standard process.

##### Configure network setup (Azure)

The module for Azure will handle the networking by default by setting up the infrastructure on the default network stack as provided by Azure. It's possible to adjust network rules if needed. To learn more refer to [Configuring Network CIDR Access](environment_advanced_network.md#configuring-network-cidr-access).

#### Configure Authentication (Azure)

Finally the last thing to configure is authentication. This is required so Terraform can access Azure (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) and [backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html), you can select any method that is desired.

If you are planning to run the toolkit locally it'll be easier to use [Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli) authentication method. Otherwise you can use either a Service Principal or Managed Service Identity when running Terraform non-interactively, please refer to [Authenticating to Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure) documentation for details. Once you have selected the authentication method and obtained the credentials you may export them as Environment Variables following the Terraform instructions for the specific authentication type to fully authenticate for both the provider and backend.

### Sensitive variable handling in Terraform

There may be times when you have to pass in sensitive variables in the Terraform modules, such as passwords for [Cloud Services](environment_advanced_services.md).

The Toolkit has been designed to be open in terms of sensitive variables as there are various strategies that could be used to secure them depending on your preferences. As long as the variables are configured in Terraform at runtime the Toolkit isn't concerned where they come from.

Some of these strategies are Environment Variables and [Terraform Data Sources](https://www.terraform.io/docs/language/data-sources/index.html), the latter being able to pull in variables from various sources such as Secret Managers.

Below are some examples of select sources that are well suited to this.

#### Environment Variables

[Terraform can read any Environment Variable on the machine running it](https://www.terraform.io/docs/cli/config/environment-variables.html#tf_var_name) with the prefix `TF_VAR_*`.

Terraform will treat all `TF_VAR_*` environment variables as variables and you can set those in your config as desired. This is ideal for sensitive variables and in CI for overriding any variables as desired.

As an example, on an AWS environment, if you wanted to set the `ssh_public_key_file` variable via an Environment Variable you would just set `TF_VAR_ssh_public_key_file` and run as normal.

#### Terraform Data Sources

Terraform has multiple [Data Sources](https://www.terraform.io/docs/language/data-sources/index.html) available depending on the cloud provider that you can utilize to pull in variables from other sources, such as Secret Managers.

As the Terraform config files you've configured are normal Terraform files, you can configure Data Sources to first collect variables and then pass them into the Toolkit's modules.

As an example, on an AWS environment, if you wanted to set the `ssh_public_key` variable via a JSON Key-Value secret that's named the same with a key also under the same name on [AWS Secret Manager](https://aws.amazon.com/secrets-manager/) you would use the [`aws_secretsmanager_secret_version` data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) as follows:

```tf
data "aws_secretsmanager_secret_version" "ssh_public_key" {
  secret_id = "ssh_public_key"
}

module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = jsondecode(aws_secretsmanager_secret_version.ssh_public_key.secret_string)["ssh_public_key"]
[...]
}
```

Any Terraform Data Source can be used in a similar way. Refer to the specific Data Source docs for more info.

## 4. Run the GitLab Environment Toolkit's Docker container (optional)

Before running the [Docker container](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/container_registry/2697240) you will need to setup your environment config files by following [# 2. Setup the Environment's config](#3-setup-the-environments-config). The container can be started once the Terraform config has been setup. When starting the container it is important to pass in your config files and keys, as well as set any authentication based environment variables.

Below is an example of how to run the container when using a GCP service account:

```sh
docker run -it \
  -e GOOGLE_APPLICATION_CREDENTIALS="/gitlab-environment-toolkit/keys/<service account file>" \
  -v <path to keys directory>:/gitlab-environment-toolkit/keys \
  -v <path to Terraform config>:/gitlab-environment-toolkit/terraform/environments/<environment name> \
  registry.gitlab.com/gitlab-org/gitlab-environment-toolkit:latest
```

You can also use a simplified command if you store your config outside of the toolkit. Using the folder structure below you're able to store multiple environments alongside each other and when using the Toolkits container you can simply pass in a single folder and still have access to all your different environments.

```sh
get_environments
├──keys
└──<environment name>
|  └──terraform
|     ├── environment.tf
|     ├── main.tf
|     └── variables.tf
└──<environment name>
   └──terraform
```

```sh
docker run -it \
  -e GOOGLE_APPLICATION_CREDENTIALS="/gitlab-environment-toolkit/keys/<service account file>" \
  -v <path to `get_environments` directory>:/environments \
  registry.gitlab.com/gitlab-org/gitlab-environment-toolkit:latest
```

## 5. Provision

After the config has been setup you're now ready to provision the environment. This is done as follows:

1. `cd` to the environment's directory under `terraform/environments` if not already there.
1. First run `terraform init` to initialize Terraform and perform required preparation such as downloading required providers, etc...
    - `terraform init --reconfigure` may need to be run sometimes if the config has changed, such as a new module path or provider version.
1. You can next optionally run `terraform plan` to view the current state of the environment and what will be changed if you proceed to apply.
1. To apply any changes run `terraform apply` and select yes
    - **Warning - running this command will likely apply changes to shared infrastructure. Only run this command if you have permission to do so.**

:information_source:&nbsp; If you ever want to deprovision resources created, you can do so by running [terraform destroy](https://www.terraform.io/docs/cli/commands/destroy.html).

## Next Steps

After the above steps have been completed you can proceed to [Configuring the environment with Ansible](environment_configure.md).
