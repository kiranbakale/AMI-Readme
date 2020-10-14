# Preparing the toolkit

* [**GitLab Performance Environment Builder - Preparing the toolkit**](prep_toolkit.md)
* [GitLab Performance Environment Builder - Building environments](building_environments.md)

Before building environments you'll need to do some preparation for the toolkit both locally as well as on Azure.

[[_TOC_]]

## Create Azure Resource Group

Each environment needs to have its own [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) on Azure. To do this, create a group following the [official guide](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups).

## Install Terraform, Ansible and Azure CLI

Each of the tools in this toolkit themselves need to be installed beforehand. You can choose how to install both as desired as long as they're reachable on the command line after. The official installation docs for each are as follows:

* [Terraform Install Guide](https://learn.hashicorp.com/terraform/getting-started/install.html)
  * **Make sure to install the specific Terraform version as stated in the environment's `main.tf` file**. Terraform requires the version to match for all people using it. Quality team will periodically update this version after testing. Errors will be thrown by Terraform when the install version being used doesn't match what its shared State file expects.
* [Ansible Install Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* [Azure CLI Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

If you are new to any of the tools here it's also worth going through some tutorials to learn the basics. Some examples of good tutorials are:

* [Terraform Azure Tutorial](https://learn.hashicorp.com/collections/terraform/azure-get-started)
* [Ansible Tutorial](https://www.guru99.com/ansible-tutorial.html)

### Prepare Terraform State Container on Azure

One additional specific step is required for Terraform - preparing it's [State](https://www.terraform.io/docs/state/index.html). Terraform's State is integral to how it works. For every action it will store and update the state with the full environment status each time. It then refers to this for subsequent actions to ensure the environment is always exactly as configured.

To ensure the state is correct for everyone using the tool we store it in the environment's resource group under a specific container. This needs to be configured manually by us for each environment once.

To be able to store any data objects in Azure, we need to create a [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview) first. This account will then be used for both Ansible and Terraform scripts. Note if the Terraform and Ansible config files haven't been created for the environment then this can wait until the next stage where this will be done.

* [Create a storage account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create) in the intended environment's resource group. The default settings in the Azure are fine to use, however the name field should only contain lowercase letters and numbers. For example the 10k's storage account is named `gitlab10k`.
* Create a [blob container](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction#containers) named as `<env_short_name>-terraform-state` under the new storage account to store Terraform State. For example, `10k-terraform-state`.
* Configure the environment's `main.tf` to point to and use this container as Terraform's State location. This is an example of the 10k environment's [main.tf](../../terraform/10k_azure/main.tf) file with backend config:

<details>
<summary>`main.tf` example</summary>

```tf
provider "azurerm" {
  version = "~> 2.24"

  subscription_id = <subscription_id>
  client_id       = <client_id>
  client_secret   = <client_secret>
  tenant_id       = <tenant_id>

  features {}
}

terraform {
  required_version = "= 0.12.18"
  backend "azurerm" {
    resource_group_name  = "gitlab-qa-10k"

    subscription_id = <subscription_id>
    client_id       = <client_id>
    client_secret   = <client_secret>
    tenant_id       = <tenant_id>

    storage_account_name = "gitlabqa10k"
    container_name       = "10k-terraform-state"
    key                  = "10k.tfstate"
  }
}

```

</details>

* Specify storage account name in `storage_account_name` variable in the environment's `variables.tf` file. For example here is the 10k environment's [variables.tf](../../terraform/10k_azure/variables.tf) file with backend config.
* Specify storage account name in `azure_storage_account_name` variable in the environment's Ansible inventory `object-storage.yml` file. For example, here is the Azure-based 10k environment's [object-storage.yml](../../ansible/inventories/10k_azure/object-storage.yml) file.
* Copy Access key from the Storage account and save it under `azure_storage_access_key` variable in the environment's Ansible inventory `object-storage.yml` file. For example, here is the Azure-based 10k environment's [object-storage.yml](../../ansible/inventories/10k_azure/object-storage.yml) file.
  * This file should be **encrypted** when the Azure credentials will be in place, this procedure will be covered [below](#azure-service-principal).

### Install Ansible Dependencies

Ansible requires some dependencies to be installed based on how we use it. You'll need to install python package dependencies on your machine along with some community roles from [Ansible Galaxy](https://galaxy.ansible.com/home) that allow for convenient deployment of some third party applications.

To do this you only have to run the following before running Ansible:

1. `cd` to the `ansible/` directory
1. First install the python packages via `pip install -r requirements/ansible-python-packages.txt`.
    * Note it's expected you already have Python and its package manager pip installed. Additionally you may have the Python3 version of pip installed, `pip3`, and you should replace accordingly.
1. Next, run the following command to install the roles - `ansible-galaxy install -r requirements/ansible-roles.yml`
1. Note that if you're on a Mac OS machine you also need to install `gnu-tar` - `brew install gnu-tar`

## Key Generation

The builder requires several authentication keys to be generated and available in the [`keys`](../../keys) directory to build the environments. The keys required are:

* [Azure Service Principal](#azure-service-principal) credentials
* [Configuring SSH Access for VMs](#configuring-ssh-access-for-vms)
* [GitLab license](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee) key (Optional)
* [GitLab initial root password](#gitlab-initial-root-password) (Optional)

In this section we detail how to generate each.

### Azure Service Principal

Each environment should have its own resource group on Azure as well as a [Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals#service-principal-object), which Terraform and Ansible both require to be created. A Service Principal is an application within Azure Active Directory whose authentication tokens can be used as the Client ID, Client Secret, and Tenant ID fields needed by Terraform and Ansible (Subscription ID can be independently recovered from your Azure account details). These Service Principal credentials are being acquired when you [created a Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli#create-a-service-principal).

Currently, Quality are using an existing Service Principal that was created by Infrastructure team for GitLab's Azure subscription. If you can't use the existing one (i.e. if you're in a different team), please request a new Service Principal from the GitLab Infrastructure team by [raising an issue on their tracker](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues) with the `Individual_Bulk_Access_Request` template or [create one yourself](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest) if you have access to Azure AD.

Once the Service Principal credentials have been acquired, you need to configure both Terraform and Ansible to use it as follows. Due to restrictions in both tools requiring the secrets to be hardcoded in their respective credentials files we strongly recommend **encrypting** these files before committing:

* Terraform - For each environment there are two places the Service Principal credentials needs to be configured, one for the State object storage and the other for the main Azure access. Configure the credentials in the `main.tf` path.
  * As an example you can refer to the current environment projects. For example the 10k environment's [`main.tf`](../../terraform/10k_azure/main.tf) file:

<details>
<summary>`main.tf` example</summary>

```tf
provider "azurerm" {
  version = "~> 2.24"

  subscription_id = <subscription_id>
  client_id       = <client_id>
  client_secret   = <client_secret>
  tenant_id       = <tenant_id>

  features {}
}

terraform {
  required_version = "= 0.12.18"
  backend "azurerm" {
    resource_group_name  = "gitlab-qa-10k"

    subscription_id = <subscription_id>
    client_id       = <client_id>
    client_secret   = <client_secret>
    tenant_id       = <tenant_id>

    storage_account_name = "gitlabqa10k"
    container_name       = "10k-terraform-state"
    key                  = "10k.tfstate"
  }
}

```

</details>

* Ansible - The Service Principal credentials need to be configured once for each environment in the inventory file.
  * For example, look to the 10k Ansible inventory file, [`10k.azure_rm.yml`](../../ansible/inventories/10k_azure/10k.azure_rm.yml).

<details>
<summary>`10k.azure_rm.yml` example</summary>

```yml
plugin: azure_rm

include_vm_resource_groups:
- "gitlab-qa-10k"
auth_source: auto

subscription_id: "<subscription_id>"
client_id: "<client_id>"
secret: "<secret>"
tenant: "<tenant>"

keyed_groups:
- prefix: ''
  separator: ''
  key: tags.gitlab_node_type | default('ungrouped')
- prefix: ''
  separator: ''
  key: tags.gitlab_node_level | default('ungrouped')

```

</details>

* With all secrets in place, we need to [encrypt](https://github.com/AGWA/git-crypt) the data to protect secret data. Ensure that `.gitattributes` file exists both under the environment's Terraform directory and Ansible inventory directory.
* Run `git-crypt status` and ensure that [`main.tf`](../../terraform/10k_azure/main.tf), [`10k.azure_rm.yml`](../ansible/inventories/10k_azure/10k.azure_rm.yml) and [`object-storage.yml`](../../ansible/inventories/10k_azure/object-storage.yml) are encrypted.

### Configuring SSH Access for VMs

In addition to creating the Service Principal and saving the credentials we need to also setup [SSH Access](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys) for the VMs to enable SSH access, which is required by Ansible. This is done as follows:

* Generate an SSH key pair following the [official guide](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys#create-an-ssh-key-pair).
* Store the SSH key pair in the [`keys`](../../keys) directory.
* Public key needs to be configured in the environment's Terraform module `variables.tf` file by setting `ssh_public_key_file_path` to the relative path of the private key file.
* Private key needs to be configured in the Ansible inventory `vars.yml` by setting `ansible_ssh_private_key_file` to the relative path of the private key file.

### GitLab License key

A GitLab License key (Ultimate) may also be required depending on the GitLab functionality you're looking to have on the environment. The builder considers this to be optional though and will work without one.

To generate a key as a developer refer to the [handbook](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee). An Ultimate license key is recommended to enable all features.

After the key is generated you can point the builder to configure the environment with it by setting the `gitlab_license_file` variable to its relative path in the Ansible inventory `vars.yml` file.

### GitLab Initial Root Password

An initial password for the GitLab root user can be provided by creating a file with the name `gitlab_root_password` in the [`keys`](../../keys) directory. The file should just contain the password to use and nothing else. If you would prefer a random password to be generated then you do not create this file, if the file is not present then a random 15 character password will be generated and the `gitlab_root_password` file will be created in the [`keys`](../../keys) directory.

This password will only take effect for new environment builds. For existing environments, the password used during the first build will still be used.

## Public Static IP Address

A static public IP is also required to be generated manually outside of Terraform. This will be the main IP for accessing the environment and is required separately due to Terraform needing full control over everything it creates so in the case of a teardown it would destroy this IP and break any DNS entries.

A new IP can be generated by following the [Public Static IP Addresses](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-public-ip-address#create-a-public-ip-address) guide and these recommendations:

* Specify your resource group in which the Public IP should be created.
* Select [*Standard* SKU](https://docs.microsoft.com/en-us/azure/virtual-network/public-ip-addresses#standard) to ensure that the allocation is static.
* Follow a simple naming convention for the name. For example, `10k-external-ip`.

Once the new IP is created take note of the IP address's name itself as it will need to be added to the environment's Terraform `variables.tf` file as the `external_ips` variable under the `external_ip_name` variable. You can refer to the existing environment scripts for reference, for example [`terraform/10k_azure/variables.tf`](../../terraform/10k_azure/variables.tf) file.
