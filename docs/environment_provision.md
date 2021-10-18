# Provisioning the environment with Terraform

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [**GitLab Environment Toolkit - Provisioning the environment with Terraform**](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Cloud Services](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo, Advanced Search, Custom Config and more](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)

With [Terraform](https://www.terraform.io/) you can automatically provision machines and associated dependencies on a provider.

The Toolkit provides multiple curated [Terraform Modules](../terraform/modules) that will provision the machines for a GitLab environment as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/).

[[_TOC_]]

## 1. Install Terraform

For the Toolkit we recommend Terraform `1.x` but versions from `0.14.x` versions should continue to work.

Terraform generally works best when all users for an environment are using the same major version due to its State. Improvements have been made that allow for the easier upgrading and downgrading of state however. As such it's recommended that all users sync on the same version of Terraform when working against the same environment and any Terraform upgrades are done in unison.

With the above considerations then we recommend installing Terraform with a Version Manager such as [`asdf`](https://asdf-vm.com/#/) (if supported on your machine(s)).

Installing Terraform with a version manager such as `asdf` has several benefits:

- It's significantly easier to install and switch between multiple versions of Terraform.
- The Terraform version can be specified in a `.tool-versions` file which `asdf` will look for and automatically switch to.
- Being able to switch Terraform versions is particularly useful if you're using the Toolkit to manage multiple environments where versions differ.

Installing Terraform with `asdf` is done as follows:

1. Install `asdf` as per its [documentation](https://asdf-vm.com/#/core-manage-asdf?id=install)
1. Add the Terraform `asdf` plugin - `asdf plugin add terraform`
1. Install the intended Terraform version - `asdf install terraform 0.14.4`
1. Set that version to be the main on your PATH - `asdf global terraform 0.14.4`

With the above completed Terraform should now be available on your command line. You can check this by running `terraform version`.

## 2. Setup the Environment's config

As mentioned the Toolkit provides several [Terraform Modules](../terraform/modules) that can be used to provision the environment as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/). While there are several modules provided with the Toolkit most of these are under the hood. For most users only one easy to use `ref_arch` module will need to be configured.

The `ref_arch` modules configure not only the VMs required for the environment but also things such as storage buckets, networking, labels for Ansible to use and more. There's one `ref_arch` module per host provider and for each there are 3 config files to setup:

- `main.tf` - Contains the main Terraform connection settings such as cloud provider, state backend, etc...
- `environment.tf` - `ref_arch` module configuration (machine count, sizes, etc...)
- `variables.tf` - Variable definitions

Each of the above files must be set in the same folder for Terraform to merge. Due to relative path requirements in Terraform we recommend you create these in a unique folder for your environment under the provided [`terraform/environments` folder](../terraform/environments), e.g. `terraform/environments/<env_name>`. These docs will assume this is the case from now on.

In this step there are sections for each supported host provider on how to configure the above files. Follow the section for your selected provider and then move onto the next step.

### Google Cloud Platform (GCP)

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on GCP is **[`gitlab_ref_arch_gcp`](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/tree/main/terraform/modules/gitlab_ref_arch_gcp)**.

In this section we detail all that's needed to configure it.

#### Configure Variables - `variables.tf`

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
- `zone` - The GCP zone of the project, e.g. `us-east1-c`.
- `external_ip` - The static external IP the environment will be accessible one. Previously created in the [Create Static External IP - GCP](environment_prep.md#6-create-static-external-ip-gcp) step.

#### Configure Terraform settings - `main.tf`

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
      version = "~> 3"
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
  - `zone` - The GCP zone of the project. Set in `variables.tf`.

#### Configure Module settings - `environment.tf`

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

##### Configure network setup (GCP)

The module for GCP can configure the [network stack](https://cloud.google.com/vpc/docs/vpc) (VPC, Subnets, etc...) for your environment in several different ways:

- **Default** - Sets up the infrastructure on the default network stack as provided by GCP. This is the default for the module.
- **Created** - Creates the required network stack for the infrastructure.
- **Existing** - Will use a provided network stack passed in by the user.

In this section you will find the config required to set up each depending on your requirements.

**{-NOTE: Changing network setup on an existing environment must be treated with the utmost caution-}**. **Doing so can be considered a significant change in GCP and may trigger the recreation of the entire environment leading to data loss**.

**Default**

This is the default setup for the module and is the recommended setup for most standard (Omnibus) environments where GCP will handle the networking by default.

No additional configuration is needed to use this setup.

**Created**

When configured the module will create a network stack to run the environment in. The network stack created is as follows:

- 1 VPC
- 1 Subnet
- Firewall rules to allow for required network connections

The environment's machines will be created in the created subnet.

This setup is recommended for users who want a specific network stack for their GitLab environment.

To configure this setup the following config should be added to the [module's environment config file](#configure-module-settings-environmenttf):

- `create_network` - This variable should be set to `true` when you are wanting the module to create a new network stack.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  create_network = true

  [...]
```

In addition to the above the following _optional_ settings change how the network is configured:

- `subnet_cidr`- A [CIDR block](https://cloud.google.com/vpc/docs/vpc#manually_created_subnet_ip_ranges) that will be used for the created subnet. This shouldn't need to be changed in most scenarios unless you want to use a specific CIDR blocks. Default is `"10.86.0.0/16"`

**Existing**

In this setup you have an existing network stack that you want the environment to use.

This is an advanced setup and you must ensure the network stack is configured correctly. This guide doesn't detail the specifics on how to do this but generally a stack should include the same elements as listed in the **Created** for the environment to work properly. Please refer to the GCP docs for more info.

Note that when this is configured the module will configure some GCP Firewall rules in your VPC to enable network access for the environment.

With an existing stack configure the following config should be added to the [module's environment config file](#configure-module-settings-environmenttf):

- `vpc_name` - The name of your existing VPC.
- `subnet_name` - The name of your existing Subnet. The subnet should be located in the same existing VPC.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  vpc_name = "<vpc-name>"
  subnet_name = "<subnet-name>"

  [...]
```

#### Configure Authentication (GCP)

Finally the last thing to configure is authentication. This is required so Terraform can access GCP (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication) and [backend](https://www.terraform.io/docs/language/settings/backends/gcs.html#configuration-variables), you can select any method that is desired.

All of the methods given involve the Service Account file you generated previously. We've found the authentication methods that work best with the Toolkit in terms of ease of use are as follows:

- `GOOGLE_CREDENTIALS` environment variable - This environment variable is picked up by both the provider and backend, meaning it only needs to be set once. It's particularly useful with CI pipelines. The variable should be set to the path of the Service Account file.
- `gcloud` login - Authentication can also occur automatically through the [`gcloud`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default) command line tool. Make sure the user that's logged in has access to the Project along with the `editor` role attached.

### Amazon Web Services (AWS)

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on AWS is **[`gitlab_ref_arch_aws`](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/tree/main/terraform/modules/gitlab_ref_arch_aws)**.

In this section we detail all that's needed to configure it.

#### Configure Variables - `variables.tf`

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
- `external_ip_allocation` - The static external IP the environment will be accessible one. Previously created in the [Create Static External IP - AWS Elastic IP Allocation](environment_prep.md#4-create-static-external-ip-aws-elastic-ip-allocation) step.

#### Configure Terraform settings - `main.tf`

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
      version = "~> 3"
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

#### Configure Module settings - `environment.tf`

Next to configure is `environment.tf`. This file contains all the config for the `gitlab_ref_arch_aws` module such as instance counts, instance sizes, external IP, etc...

How you configure this file depends on the size of [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/) you want to deploy. Below we show how a [10k](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) `environment.tf` would be set. If a different size is required all that's required is to tweak the machine counts and sizes to match the desired Reference Architecture as shown in the [docs](https://docs.gitlab.com/ee/administration/reference_architectures/).

Here's an example of the file with all config for a [10k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) and descriptions below:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key_file = file(var.ssh_public_key_file)

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
  - `ssh_public_key_file` - The file path of the public SSH key. Set in `variables.tf`.

Next in the file are the various machine settings, separated the same as the Reference Architectures. To avoid repetition we'll describe each setting once:

- `*_node_count` - The number of machines to set up for that component
- `*_instance_type` - The [AWS Instance Type Machine Type](https://aws.amazon.com/ec2/instance-types/) (size) for that component
- `haproxy_external_elastic_ip_allocation_ids` - Set the external HAProxy load balancer to assume the external IP allocation ID set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP allocation ID.

##### Configure network setup (AWS)

The module for AWS can configure the [network stack](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html) (VPC, Subnets, etc...) for your environment in several different ways:

- **Default** - Sets up the infrastructure on the default network stack as provided by AWS. This is the default for the module.
- **Created** - Creates the required network stack for the infrastructure
- **Existing** - Will use a provided network stack passed in by the user

In this section you will find the config required to set up each depending on your requirements.

**{-NOTE: Changing network setup on an existing environment must be avoided-}**. **Doing so is considered a significant change in AWS and will essentially trigger the recreation of the entire environment leading to data loss**.

**Default**

This is the default setup for the module and is the recommended setup for most standard (Omnibus) environments where AWS will handle the networking by default.

No additional configuration is needed to use this setup. However several parts of the provisioned architecture may require attaching to a number of Subnets in the network stack to function correctly. The actual number of subnets to be attached can be configured as follows:

- `default_subnet_use_count` - Set to the number of subnets in the default network stack that should be attached to by parts that require it. Default is 2.

**Created**

When configured the module will create a network stack to run the environment in. The network stack created is as follows:

- 1 VPC
- 2 Subnets
  - Subnets are created in the created VPC and are additionally spread across the available Availability Zones in the selected region.
  - The number of Subnets is configurable.
- 1 Internet Gateway
- 1 Route Table

The environment's machines will be spread across the created subnets and their Availability Zones evenly.

This setup is recommended for users who want a specific network stack for their GitLab environment. It's also recommended for Cloud Native Hybrid environments running on AWS.

To configure this setup the following config should be added to the [module's environment config file](#configure-module-settings-environmenttf-1):

- `create_network` - This variable should be set to `true` when you are wanting the module to create a new network stack.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key_file = file(var.ssh_public_key_file)

  create_network = true

  [...]
```

In addition to the above the following _optional_ settings change how the network is configured:

- `subnet_pub_count` - The number of subnets to create in the VPC. This should only be changed if you want increased subnet count for availability reasons. Default is `2`.
- `vpc_cidr_block` - The [CIDR block](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4) that will be used for your VPC. This shouldn't need to be changed in most scenarios unless you want to use a specific CIDR block. Default is `172.31.0.0/16`.
- `subpub_pub_cidr_block`- A list of [CIDR blocks](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4) that will be used for each subnet created. This shouldn't need to be changed in most scenarios unless you want to use a specific CIDR blocks. Default is `["172.31.0.0/20","172.31.16.0/20","172.31.32.0/20"]`
  - As a convenience the module has up to 3 subnet CIDR blocks it will use. If you have set `subnet_pub_count` higher than 3 then this variable will need to be adjusted to match the number of Subnets to be created.

**Existing**

In this setup you have an existing network stack that you want the environment to use.

This is an advanced setup and you must ensure the network stack is configured correctly. This guide doesn't detail the specifics on how to do this but generally a stack should include the same elements as listed in the **Created** for the environment to work properly. Please refer to the AWS docs for more info.

Note that when this is configured the module will configure some AWS Security Groups in your VPC to enable network access for the environment.

With an existing stack configure the following config should be added to the [module's environment config file](#configure-module-settings-environmenttf-1):

- `vpc_id` - The ID of your existing VPC
- `subnet_ids` - A list of Subnet IDs the environment's machines should be spread across. The subnets should be located in the same existing VPC.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key_file = file(var.ssh_public_key_file)

  vpc_id = "<vpc-id>"
  subnet_ids = ["<subnet-1-id>", "<subnet-2-id>"]

  [...]
```

#### Configure Authentication (AWS)

Finally the last thing to configure is authentication. This is required so Terraform can access AWS (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) and [backend](https://www.terraform.io/docs/language/settings/backends/s3.html#configuration), you can select any method that is desired.

All of the methods given involve the AWS Access Key you generated previously. We've found that the easiest and secure way to do this is with the official [environment variables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables):

- `AWS_ACCESS_KEY_ID` - Set to the AWS Access Key.
- `AWS_SECRET_ACCESS_KEY` - Set to the AWS Secret Key.

Once the two variables are either set locally or in your CI pipeline Terraform will be able to fully authenticate for both the provider and backend.

### Azure

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on Azure is **[`gitlab_ref_arch_azure`](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/tree/main/terraform/modules/gitlab_ref_arch_azure)**.

In this section we detail all that's needed to configure it.

#### Configure Variables - `variables.tf`

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

#### Configure Terraform settings - `main.tf`

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
      version = "~> 2"
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

#### Configure Module settings - `environment.tf`

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
  ssh_public_key_file_path = var.ssh_public_key_file_path

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
  - `ssh_public_key_file_path` - The file path of the public SSH key. Set in `variables.tf`.

Next in the file are the various machine settings, separated the same as the Reference Architectures. To avoid repetition we'll describe each setting once:

- `*_node_count` - The number of machines to set up for that component
- `*_size` - The [Azure Machine Size](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes) for that component
- `haproxy_external_external_ip_names` - Set the external HAProxy load balancer to assume the external IP name set in `variables.tf`. Note that this is an array setting as the advanced underlying functionality needs to account for the specific setting of IPs for potentially multiple machines. In this case though it should always only be one IP name.

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

As an example, on an AWS environment, if you wanted to set the `ssh_public_key_file` variable via a JSON Key-Value secret that's named the same with a key also under the same name on [AWS Secret Manager](https://aws.amazon.com/secrets-manager/) you would use the [`aws_secretsmanager_secret_version` data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) as follows:

```tf
data "aws_secretsmanager_secret_version" "ssh_public_key_file" {
  secret_id = "ssh_public_key_file"
}

module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key_file = jsondecode(aws_secretsmanager_secret_version.ssh_public_key_file.secret_string)["ssh_public_key_file"]
[...]
}
```

Any Terraform Data Source can be used in a similar way. Refer to the specific Data Source docs for more info.

## 3. Provision

After the config has been setup you're now ready to provision the environment. This is done as follows:

1. `cd` to the environment's directory under `terraform/environments` if not already there.
1. First run `terraform init` to initialize Terraform and perform required preparation such as downloading required providers, etc...
    - `terraform init --reconfigure` may need to be run sometimes if the config has changed, such as a new module path or provider version.
1. You can next optionally run `terraform plan` to view the current state of the environment and what will be changed if you proceed to apply.
1. To apply any changes run `terraform apply` and select yes
    - **Warning - running this command will likely apply changes to shared infrastructure. Only run this command if you have permission to do so.**

NOTE: If you ever want to deprovision resources created, you can do so by running [terraform destroy](https://www.terraform.io/docs/cli/commands/destroy.html).

## Next Steps 

After the above steps have been completed you can proceed to [Configuring the environment with Ansible](environment_configure.md).
