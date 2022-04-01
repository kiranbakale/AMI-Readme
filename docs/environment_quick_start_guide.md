# Quick Start Guide

- [**GitLab Environment Toolkit - Quick Start Guide**](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment provider](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

On this page you'll find a Quick Start Guide where we go through the steps with examples on how to setup a GitLab environment required with the Toolkit.

For the purpose of this guide we'll go through the steps required for one of the more common setups - An [Omnibus 10k Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html) on Amazon Web Services (AWS). All resources will be created in the `US East (N. Virginia)` region, this will be referred to as `us-east-1` whenever a region is required throughout this guide.

:information_source:&nbsp; This quick guide won't cover all the potential options available and assumes a working knowledge of the Toolkit, Terraform, Ansible and GitLab. It's recommended you still read the docs in full to ensure the environment is configured as per your requirements.

[[_TOC_]]

## 1. Preparing the environment provider

The first step is to [prepare the environment's provider](environment_prep.md). This includes setting up authentication, SSH key, Terraform State and configuring an IP for the environment.

Let's go through each for AWS:

### 1a. Authentication

First we need to sort how Terraform and Ansible will authenticate against AWS.

- [Generate an Access Key on AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) for the user you intend the Toolkit to use.
- Take the key values and set them to the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` respectively on the machine you're running the Toolkit

### 1b. SSH Key

Next we need an SSH key to be configured on the machines to allow Ansible access directly to the boxes.

Generating the key itself is as normal and covered in the main [GitLab docs](https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair). Save the key to a location that's reachable by the Toolkit, which we'll configure later on to use this key.

:information_source:&nbsp; _For the purposes of this guide we'll use a public key named **`gitlab-10k.pub`** saved in the location **`gitlab-environment-toolkit/keys`**_.

### 1c. Terraform State Storage

Next we need a place to save the Terraform State file. It's recommended this is in a remote location so all users ensure they're on the same state.

With AWS this is straightforward as we can store the file on S3 object storage. Create a standard [AWS storage bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html) for this.

:information_source:&nbsp; _For the purposes of this guide we'll create a bucket named **`gitlab-10k-terraform-state`**_.

:information_source:&nbsp; You will need to use your own name for the bucket here, this is because bucket names are global in AWS and you will likely get a naming conflict using **`gitlab-10k-terraform-state`**

### 1d. Static External IP

Finally the last bit of prep we need is a Static External IP that the environment will use as its address.

Follow [AWS's docs on how to do this](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html#using-instance-addressing-eips-allocating), selecting the default options.

Once created you'll be given an allocation ID. Keep a note of this to be used later.

:information_source:&nbsp; _For the purposes of this guide we'll use the IP `65.228.130.134` that has the allocation ID **`eipalloc-VoWQKqdu42P8aYoy0`**_.

## 2. Provisioning the environment with Terraform

With the prep done [we're now ready to setup the config for Terraform to provision](environment_provision.md) the environment's infrastructure on AWS. This involves installing Terraform, setting up the config and then running Terraform.

Let's go through the steps for each.

:information_source:&nbsp; _For the purposes of this guide we're running the Toolkit natively from source where the modules are all available on disk. Config is setup in the **`gitlab-environment-toolkit/terraform/environments/gitlab-10k`** folder_.

### 2a. Installing Terraform with `asdf`

First we need to install Terraform. To easily switch between Terraform versions we recommend to install via [`asdf`](https://asdf-vm.com/#/) as follows:

1. Install asdf as per its documentation
1. Add the Terraform asdf plugin - `asdf plugin add terraform`
1. Install the intended Terraform version - `asdf install terraform 1.0.0`
1. Set that version to be the main on your PATH - `asdf global terraform 1.0.0`

Terraform should now be installed and ready on your `PATH`.

### 2b. Setup Config

Now we'll setup the Terraform config for the environment. There are 3 config files to configure - Variables (`variables.tf`), Main (`main.tf`) and Environment (`environment.tf`) - as follows:

First is the Variables file, which contains some variables to be used by Terraform for connecting to AWS as well as setting some environment basics such as the AWS Region:

<details><summary>Variables - <code>gitlab-environment-toolkit/terraform/environments/gitlab-10k/variables.tf</code></summary>

```tf
variable "prefix" {
  default = "gitlab-10k"
}

variable "region" {
  default = "us-east-1"
}

variable "ssh_public_key_file" {
  default = "../../keys/gitlab-10k.pub"
}

variable "external_ip_allocation" {
  default = "eipalloc-VoWQKqdu42P8aYoy0"
}
```

</details>

Next is the Main file, which configures Terraform how to authenticate against AWS and where to save it's state:

<details><summary>Main - <code>gitlab-environment-toolkit/terraform/environments/gitlab-10k/main.tf</code></summary>

```tf
terraform {
  backend "s3" {
    bucket = "gitlab-10k-terraform-state"
    key    = "gitlab-10k.tfstate"
    region = "us-east-1"
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

</details>

Finally we have the Environment file, which configures the Toolkit's modules on how to actually build the environment:

<details><summary>Environment - <code>gitlab-environment-toolkit/terraform/environments/gitlab-10k/environment.tf</code></summary>

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

</details>

With the above config in place we should now be ready to run Terraform.

### 2c. Provision

The machines and infrastructure are now ready to be provisioned with Terraform. This is done via a few commands as follows:

1. Change to the Terraform directory - `cd gitlab-environment-toolkit/terraform/environments/gitlab-10k`.
1. Run `terraform init` to initialize Terraform and perform required preparation such as downloading required providers. This typically only needs to be run once for the first build or after any notable config changes.
1. Run `terraform apply` to actually provision the infrastructure, a confirmation prompt will be shown by Terraform before proceeding.

After Terraform has finished running, the machines and other infrastructure will now be provisioned.

## 3. Configuring the environment with Ansible

With the machines and infrastructure provisioned, we're now ready to [setup Ansible to configure GitLab](environment_configure.md). This involves installing Ansible, setting up the config and then running Ansible.

Let's go through the steps for each.

:information_source:&nbsp; _For the purposes of this guide we're running the Toolkit natively from source where the playbooks and roles are all available on disk. Config is setup in the **`gitlab-environment-toolkit/ansible/environments/gitlab-10k/inventory`** folder_.

### 3a. Installing Ansible with a Virtual Environment

First we need to install Ansible. There are various ways to install Ansible, we recommend using Python in a Virtual Environment. Once installed we also need to install some Python and Ansible packages. The steps for all of this are as follows:

1. Create a virtual environment called `get-python-env` - `python3 -m venv get-python-env`
1. Activate the new environment - `. ./get-python-env/bin/activate`
1. Install Ansible - `pip3 install ansible`
1. Install Python packages - `pip3 install -r gitlab-environment-toolkit/ansible/requirements/requirements.txt`.
1. Install Ansible Galaxy Collections and Roles - `ansible-galaxy install -r gitlab-environment-toolkit/ansible/requirements/ansible-galaxy-requirements.yml`.
1. Install OpenSSH Client if not already installed - E.G. for Ubuntu `apt-get install openssh-client`.
1. Note that if you're on a Mac OS machine you also need to install `gnu-tar` - `brew install gnu-tar`.

### 3b. Setup Config

Now we'll setup the Ansible config for the environment. There are 2 config files to configure - Dynamic Inventory (`gitlab_10k.aws_ec2.yml`) and Environment (`vars.yml`) - as follows:

:information_source:&nbsp; Note that some of the config we set here matches config set in Terraform.

First is the Dynamic Inventory file, which configures Ansible to retrieve the machine list from AWS and their details:

<details><summary>Dynamic Inventory - <code>gitlab-environment-toolkit/ansible/environments/gitlab-10k/inventory/gitlab_10k.aws_ec2.yml</code></summary>

```yaml
plugin: aws_ec2
regions:
  - us-east-1
filters:
  tag:gitlab_node_prefix: gitlab-10k
keyed_groups:
  - key: tags.gitlab_node_type
    separator: ''
  - key: tags.gitlab_node_level
    separator: ''
hostnames:
  # List host by name instead of the default public ip
  - tag:Name
compose:
  # Use the public IP address to connect to the host
  # (note: this does not modify inventory_hostname, which is set via I(hostnames))
  ansible_host: public_ip_address
```

:information_source:&nbsp; Barring `regions` and `filters` the config file should always match the above for AWS. It also must be saved with the suffix `aws_ec2.yml`.

</details>

Next is the Environment config file that contains all the config for configuring GitLab:

<details><summary>Environment - <code>gitlab-environment-toolkit/ansible/environments/gitlab-10k/inventory/vars.yml</code></summary>

```yaml
all:
  vars:
    # Ansible Settings
    ansible_user: "ubuntu"
    ansible_ssh_private_key_file: "../../keys/gitlab-10k.pub"

    # Cloud Settings, available options: gcp, aws, azure
    cloud_provider: "aws"

    # AWS only settings
    aws_region: "us-east-1"

    # General Settings
    prefix: "gitlab-qa-10k"
    external_url: "http://65.228.130.134"

    # Passwords / Secrets
    gitlab_root_password: '<gitlab_root_password>'
    grafana_password: '<grafana_password>'
    postgres_password: '<postgres_password>'
    consul_database_password: '<consul_database_password>'
    gitaly_token: '<gitaly_token>'
    pgbouncer_password: '<pgbouncer_password>'
    redis_password: '<redis_password>'
    praefect_external_token: '<praefect_external_token>'
    praefect_internal_token: '<praefect_internal_token>'
    praefect_postgres_password: '<praefect_postgres_password>'
```

:information_source:&nbsp; Passwords shown above are only for illustration practices and should not be used in any environment under any circumstances.

</details>

### 3c. Configure

GitLab is now ready to be configured with Ansible. This is done via a few commands as follows:

1. Change to the Ansible directory - `cd gitlab-environment-toolkit/ansible`.
1. Run `ansible-playbook -i environments/gitlab-10k/inventory playbooks/all.yml` to run through all the playbooks and configure GitLab.

After Ansible has finished running, GitLab will now be configured and the environment ready to go.

## Config Examples

[Full config examples are available for select Reference Architectures](../examples).

## Next Steps

Depending on your requirements the following might be worth reviewing next:

- [Upgrade Notes](environment_upgrades.md)
- [Adding Geo](environment_advanced_geo.md)
- [Considerations After Deployment - Backups, Security](environment_post_considerations.md)

You may also want to review the various Advanced setup options in the docs.
