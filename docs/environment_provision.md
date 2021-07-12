# Provisioning the environment with Terraform

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [**GitLab Environment Toolkit - Provisioning the environment with Terraform**](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Customizations](environment_advanced.md)
  - [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)

With [Terraform](https://www.terraform.io/) you can automatically provision machines and associated dependencies on a provider.

The Toolkit provides multiple curated [Terraform Modules](../terraform/modules) that will provision the machines for a GitLab environment as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/).

[[_TOC_]]

## 1. Install Terraform

The Toolkit requires Terraform `0.14.x` to be installed. It can be installed as desired but be aware that **{-Terraform's State file generally requires all users to be running the exact same version of Terraform-}**. 

With the above caveat we recommend that the version of Terraform to be used is agreed between all potential users. We further recommend installing Terraform with a Version Manager such as [`asdf`](https://asdf-vm.com/#/) (if supported on your machine(s)).

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

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on GCP is **[`gitlab_ref_arch_gcp`](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/tree/master/terraform/modules/gitlab_ref_arch_gcp)**.

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
  redis_sentinel_cache_node_count = 3
  redis_sentinel_cache_machine_type = "n1-standard-1"
  redis_persistent_node_count = 3
  redis_persistent_machine_type = "n1-standard-4"
  redis_sentinel_persistent_node_count = 3
  redis_sentinel_persistent_machine_type = "n1-standard-1"

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

#### Configure Authentication (GCP)

Finally the last thing to configure is authentication. This is required so Terraform can access GCP (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication) and [backend](https://www.terraform.io/docs/language/settings/backends/gcs.html#configuration-variables), you can select any method that is desired.

All of the methods given involve the Service Account file you generated previously. We've found the authentication methods that work best with the Toolkit in terms of ease of use are as follows:

- `GOOGLE_CREDENTIALS` environment variable - This environment variable is picked up by both the provider and backend, meaning it only needs to be set once. It's particularly useful with CI pipelines. The variable should be set to the path of the Service Account file.
- `gcloud` login - Authentication can also occur automatically through the [`gcloud`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default) command line tool. Make sure the user that's logged in has access to the Project along with the `editor` role attached.

### Amazon Web Services (AWS)

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on AWS is **[`gitlab_ref_arch_aws`](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/tree/master/terraform/modules/gitlab_ref_arch_aws)**.

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
  redis_sentinel_cache_node_count = 3
  redis_sentinel_cache_instance_type = "c5.large"
  redis_persistent_node_count = 3
  redis_persistent_instance_type = "m5.xlarge"
  redis_sentinel_persistent_node_count = 3
  redis_sentinel_persistent_instance_type = "c5.large"

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

#### Configure Authentication (AWS)

Finally the last thing to configure is authentication. This is required so Terraform can access AWS (provider) as well as its State Storage Bucket (backend).

Terraform provides multiple ways to authenticate with the [provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) and [backend](https://www.terraform.io/docs/language/settings/backends/s3.html#configuration), you can select any method that is desired.

All of the methods given involve the AWS Access Key you generated previously. We've found that the easiest and secure way to do this is with the official [environment variables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables):

- `AWS_ACCESS_KEY_ID` - Set to the AWS Access Key.
- `AWS_SECRET_ACCESS_KEY` - Set to the AWS Secret Key.

Once the two variables are either set locally or in your CI pipeline Terraform will be able to fully authenticate for both the provider and backend.

### Azure

The Toolkit's module for seamlessly setting up a full GitLab Reference architecture on Azure is **[`gitlab_ref_arch_azure`](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/tree/master/terraform/modules/gitlab_ref_arch_azure)**.

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
  - `features` - Used to [customize the behaviour](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#features) of certain Azure Provider resources.

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
  redis_sentinel_cache_node_count = 3
  redis_sentinel_cache_size = "Standard_A1_v2"
  redis_persistent_node_count = 3
  redis_persistent_size = "Standard_D4s_v3"
  redis_sentinel_persistent_node_count = 3
  redis_sentinel_persistent_size = "Standard_A1_v2"

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

### Further Config Examples

The Quality team actively use the Toolkit daily to build and test various environments, including at least one of each Reference Architecture size.

These are stored on a different project and can be viewed [here](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit-configs/quality) for further reference (although note some files are encrypted to protect secrets).

## 3. Provision

After the config has been setup you're now ready to provision the environment. This is done as follows:

1. `cd` to the environment's directory under `terraform/environments` if not already there.
1. First run `terraform init` to initialize Terraform and perform required preparation such as downloading required providers, etc...
    - `terraform init --reconfigure` may need to be run sometimes if the config has changed, such as a new module path or provider version.
1. You can next optionally run `terraform plan` to view the current state of the environment and what will be changed if you proceed to apply.
1. To apply any changes run `terraform apply` and select yes
    - **Warning - running this command will likely apply changes to shared infrastructure. Only run this command if you have permission to do so.**

_Note: If you ever want to deprovision resources created, you can do so by running [terraform destroy](https://www.terraform.io/docs/cli/commands/destroy.html)._

## Next Steps 

After the above steps have been completed you can proceed to [Configuring the environment with Ansible](environment_configure.md).
