# Preparing the toolkit

---
**NOTE**

The GitLab Environment Toolkit is in **Alpha** (`v1.0.0-alpha`) and work is currently under way for its main release.

As such, **this documentation is currently out of date** but we aim to have this updated soon.

For more information about this release please refer to this [Epic](https://gitlab.com/groups/gitlab-org/-/epics/5061).

---

- [**GitLab Environment Toolkit - Preparing the toolkit**](prep_toolkit.md)
- [GitLab Environment Toolkit - Building environments](building_environments.md)
- [GitLab Environment Toolkit - Building an environment with Geo](building_geo_environments.md)

To start using the Toolkit to build environments you'll need to do some required preparation for the toolkit both locally as well as on your target cloud provider.

These docs assume working knowledge of Terraform, Ansible and the selected Cloud Platform the environment is to run on. If you are new to any of these tools we recommend reading up on these at least at a high level before proceeding.

Where stipulated you should only follow the sections relevant to the target Cloud Platform.

[[_TOC_]]

## 1. Install Terraform, Ansible and Cloud Platform tools

Each of the tools in the Toolkit need to be installed beforehand. We also recommend installing Cloud Platform tooling for easier manual management. You can choose how to install these as desired as long as they're reachable on the command line after and match the versions where stated.

### Terraform

**{-Before installing Terraform, make sure to install the specific Terraform version as stated in the environment's main.tf file-}**. If the environment is new we currently recommend installing Terraform `v0.12.18`. Terraform requires the version to match for all people using it to sync it's State correctly. The Quality team will periodically update this version after testing. Errors will be thrown by Terraform when the install version being used doesn't match what its shared State file expects.

Once you know what version to install proceed to Install Terraform on your runner machine as per the official [Terraform Install Guide](https://learn.hashicorp.com/terraform/getting-started/install.html).

### Ansible

Install Ansible on your runner machine as per the official [Ansible Install Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).

Ansible also requires some dependencies to be installed. You'll need to install Python package dependencies on your machine along with some community roles from [Ansible Galaxy](https://galaxy.ansible.com/home) that allow for convenient deployment of some third party applications.

To do this you only have to run the following before running Ansible:

1. `cd` to the `ansible/` directory
1. First install the Python packages via `pip install -r requirements/ansible-python-packages.txt`.
    - Note it's expected you already have Python and its package manager pip installed. Additionally you may have the Python3 version of pip installed, `pip3`, and you should replace accordingly.
1. Next, run the following command to install the roles - `ansible-galaxy install -r requirements/ansible-galaxy-requirements.yml`
1. Note that if you're on a Mac OS machine you also need to install `gnu-tar` - `brew install gnu-tar`

### Cloud Platform Tools

Then for the target Cloud Platform we recommend installing the following tools respectively:

- GCP - [GCloud Install Guide](https://cloud.google.com/sdk/install)
- Azure - [Azure CLI Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

## 2. Setup Resources on target Cloud Platform

### GCP - Select or Create GCP Project

Each environment is recommended to have its own project on GCP. A project can be requested from the GitLab Infrastructure team by [raising an issue on their tracker](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues) with the `group_project` template.

Existing projects can also be used but this should be checked with the Project's stakeholders as this will effect things such as total CPU quotas, etc...

### Azure - Select or Create Azure Resource Group

Each environment needs to have its own [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) on Azure.

To do this, create a group following the [official guide](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups).

## 3. Prepare Terraform State Bucket on Cloud Platform

One specific step that's important and required for Terraform is preparing it's [State](https://www.terraform.io/docs/state/index.html) file. Terraform's State is integral to how it works. For every action it will store and update the state with the full environment status each time. It then refers to this for subsequent actions to ensure the environment is always exactly as configured.

To ensure the state is correct for everyone using the toolkit we store it on the environment cloud platform in a specific bucket. This needs to be configured manually for each environment once.

Each project's State bucket is a standard one and will typically follow a simple naming convention - `<env_short_name>-terraform-state`. The name can be anything as desired though as long as it's configured subsequently in the environment's `main.tf` file.

For each Cloud Platform the above can be done as follows:

### GCP - Create Storage Bucket

- Create a standard GCP storage bucket on the intended environment's project for its Terraform State named as `<env_short_name>-terraform-state`. For example the 10k's State bucket is named `10k-terraform-state`.
- Configure the environment's `main.tf` to point to and use this bucket as Terraform's State location. For example here is the 10k environment's [main.tf](terraform/10k/main.tf) file with backend config.
  - If the Terraform config files are yet to created for the environment then this can wait until the next stage where this will be done.

### Azure - Create Storage Blob Container

- [Create a storage account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create) in the intended environment's resource group. The default settings in the Azure are fine to use, however the name field should only contain lowercase letters and numbers. For example the 10k's storage account is named `gitlab10k`.
- Create a [blob container](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction#containers) named as `<env_short_name>-terraform-state` under the new storage account to store Terraform State. For example, `10k-terraform-state`.
- Configure the environment's `main.tf` to point to and use this container as Terraform's State location. This is an example of the 10k environment's `main.tf` file with backend config:

<details>
<summary><code>main.tf</code> example</summary>

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

- Specify storage account name in `storage_account_name` variable in the environment's `variables.tf` file. For example here is the 10k environment's [variables.tf](../../terraform/10k_azure/variables.tf) file with backend config.
- Specify storage account name in `azure_storage_account_name` variable in the environment's Ansible inventory `object-storage.yml` file. For example, here is the Azure-based 10k environment's [object-storage.yml](../../ansible/inventories/10k_azure/object-storage.yml) file.
- Copy Access key from the Storage account and save it under `azure_storage_access_key` variable in the environment's Ansible inventory `object-storage.yml` file. For example, here is the Azure-based 10k environment's [object-storage.yml](../../ansible/inventories/10k_azure/object-storage.yml) file.
  - This file should be **encrypted** when the Azure credentials will be in place, this procedure will be covered [below](#azure-service-principal).

## 4. Generate Cloud Authentication Keys

Each of the tools in this Toolkit, and even GitLab itself, all require authentication to be configured in various formats as follows:

- Direct authentication with Cloud Platform (Terraform, Ansible) *GCP Service Account, Azure Service Principal*
- SSH authentication with machines (Ansible) *SSH Key*
- Authentication with Cloud Platform Object Storage (Terraform, GitLab) *GCP Service Account, Azure Storage Account*

To complicate matters further sometimes these keys need to be given in a specific type or format depending on tool, Cloud Platform or GitLab requirements. As such you should be aware of the following notes before proceeding:

- Where possible we attempt to make this as streamlined as we can but it's still an involved process as security typically involves various steps.
- As a general focus we try to go with the default of authentication keys being added to the [`keys`](../keys) folder in an encrypted fashion (Quality are currently using [`git-crypt`](https://github.com/AGWA/git-crypt) for this, if you wish to commit your own keys please reach out and we can configure the encryption for you).
- As mentioned above in some cases keys are required directly in config files depending on the tool. When this is required it will be called out in these docs and these files are recommended to be encrypted as well.

**Note: [We're looking at improving this process where possible in the future](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/issues/22)**

To configure everything as detailed above, follow the steps below for the selected Cloud Platform:

### GCP - Service Account

Each environment is recommended to have its own project on GCP. Terraform and Ansible both require a [Service Account](https://cloud.google.com/iam/docs/understanding-service-accounts) to be created. If this is a new project without a Service Account then you can create one as follows if you're an admin:

- Head to the [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page. Be sure to check that the correct project is selected in the dropdown at the top of the page.
- Proceed to create an account with a descriptive name like `gitlab-qa` with the `Compute OS Admin Login`, `Editor` and `Kubernetes Engine Admin` roles.
- On the last page there will be the option to generate a key. Select to do so with the `JSON` format and save it a reachable location that will be configured in both of the tools later.
  - If this is for a live environment the key should be added to the [`keys`](../keys) directory in this project with a reasonable naming convention like `serviceaccount-<project-name>.json`, e.g. `serviceaccount-10k.json`.
- Finish creating the user

Once the key has been saved you need to configure both Terraform and Ansible to use it as follows:

- Terraform - For each environment there are two places the Service Account key location needs to be configured, one for the State object storage and the other for the main GCP access. Configure the location in the `main.tf` and `variables.tf` files with the relative path. For `variables.tf` the path should be saved under the variable name of `credentials_file`.
  - As an example you can refer to the current environment projects. For example the 10k environment's [`main.tf`](../terraform/10k/main.tf) and [`variables.tf`](../terraform/10k/variables.tf) files.
- Ansible - The files relative path location only needs to be configured once for each environment in the inventory file under the variable name `service_account_file`.
  - For example, look to the 10k Ansible inventory file, [`10k.gcp.yml`](../ansible/inventories/10k/10k.gcp.yml).

#### Configuring SSH OS Login for Service Account

In addition to creating the Service Account and saving the key we need to also setup [OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access) for the account to enable SSH access to the created VMs on GCP, which is required by Ansible. This is done as follows:

- Generate an SSH key pair and store it in the [`keys`](../keys) directory.
- With the `gcloud` command set it to point at your intended project - `gcloud config set project <project-id>`
  - Note that you need the project's ID here and not the name. This can be seen on the home page for the project.
- Now login as the Service Account user via it's key created in the last step - `gcloud auth activate-service-account --key-file=serviceaccount-<project-name>.json`
- Proceed to add the project's public SSH key to the account - `gcloud compute os-login ssh-keys add --key-file=<SSH key>.pub`
- Next you need to get the actual Service Account SSH username for Ansible. This is in the format of `sa_<ID>`. The ID can be obtained with the following command - `gcloud iam service-accounts describe gitlab-qa@<project-id>.iam.gserviceaccount.com --format='value(uniqueId)'`. Take the ID from this command and add it to the Ansible inventory `vars.yml` file under `ansible_user` in the format `sa_<ID>`.
- For the private key this also needs to be configured in the Ansible inventory `vars.yml` by setting `ansible_ssh_private_key_file` to the relative path of the private key file.
- Finish with switching gcloud back to be logged in as your account `gcloud config set account <account-email-address>`

SSH access should now be enabled on the Service Account and this will be used by Ansible to SSH login each VM. More info on OS Login and how it's configured can be found [here](https://alex.dzyoba.com/blog/gcp-ansible-service-account/).

### Azure - Service Principal

Each environment should have its own resource group on Azure as well as a [Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals#service-principal-object), which Terraform and Ansible both require to be created. A Service Principal is an application within Azure Active Directory whose authentication tokens can be used as the Client ID, Client Secret, and Tenant ID fields needed by Terraform and Ansible (Subscription ID can be independently recovered from your Azure account details). These Service Principal credentials are being acquired when you [created a Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli#create-a-service-principal).

Currently, Quality are using an existing Service Principal that was created by Infrastructure team for GitLab's Azure subscription. If you can't use the existing one (i.e. if you're in a different team), please request a new Service Principal from the GitLab Infrastructure team by [raising an issue on their tracker](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues) with the `Individual_Bulk_Access_Request` template or [create one yourself](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest) if you have access to Azure AD.

Once the Service Principal credentials have been acquired, you need to configure both Terraform and Ansible to use it as follows. Due to restrictions in both tools requiring the secrets to be hardcoded in their respective credentials files we strongly recommend **encrypting** these files before committing:

- Terraform - For each environment there are two places the Service Principal credentials needs to be configured, one for the State object storage and the other for the main Azure access. Configure the credentials in the `main.tf` path.
  - As an example you can refer to the current environment projects. For example the 10k environment's `main.tf`:

<details>
<summary><code>main.tf</code> example</summary>

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

- Ansible - The Service Principal credentials need to be configured once for each environment in the inventory file.
  - For example, look to the 10k Ansible inventory file, `10k.azure_rm.yml`:

<details>
<summary><code>10k.azure_rm.yml</code> example</summary>

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

- With all secrets in place, we need to [encrypt](https://github.com/AGWA/git-crypt) the data to protect secret data. Ensure that `.gitattributes` file exists both under the environment's Terraform directory and Ansible inventory directory.
- Run `git-crypt status` and ensure that [`main.tf`](../../terraform/10k_azure/main.tf), [`10k.azure_rm.yml`](../ansible/inventories/10k_azure/10k.azure_rm.yml) and [`object-storage.yml`](../../ansible/inventories/10k_azure/object-storage.yml) are encrypted.

#### Configuring SSH Access for VMs

In addition to creating the Service Principal and saving the credentials we need to also setup [SSH Access](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys) for the VMs to enable SSH access, which is required by Ansible. This is done as follows:

- Generate an SSH key pair following the [official guide](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys#create-an-ssh-key-pair).
- Store the SSH key pair in the [`keys`](../../keys) directory.
- Public key needs to be configured in the environment's Terraform module `variables.tf` file by setting `ssh_public_key_file_path` to the relative path of the private key file.
- Private key needs to be configured in the Ansible inventory `vars.yml` by setting `ansible_ssh_private_key_file` to the relative path of the private key file.

## 5. Generate GitLab Authentication Config

In addition to the Cloud authentication keys above GitLab itself needs authentication config as well:

- GitLab's initial root password (GitLab, Ansible) *Password File*
- (Optional) [GitLab license](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee) (GitLab, Ansible) *License File*

### GitLab Initial Root Password

An initial password for the GitLab root user can be provided by creating an encrypted file with in the [`keys`](../keys) directory. After the file is generated you can configure the environment to use it by setting the `gitlab_root_password_file` variable to its relative path in the Ansible inventory `vars.yml` file. The file should just contain the password to use and nothing else.

At a minimum you need to set where the `gitlab_root_password_file` will be located for Ansible to read it. If the file doesn't exist Ansible will proceed to generate a file containing the new 15 character length password for you. We recommend generating the file yourself however with the password you want and then encrypting it accordingly before committing.

Note that the password will only take effect for new environment builds. For existing environments, the password used during the first build will still be used. If the password is changed on the environment it should also be changed in the `gitlab_root_password_file` as the Toolkit requires the password to set some settings via API calls.

### GitLab License key (optional)

A GitLab License key (Ultimate) may also be required depending on the GitLab functionality you're looking to have on the environment. The Toolkit considers this to be optional though and will work without one.

To generate a key as a developer refer to the [handbook](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee). An Ultimate license key is recommended to enable all features.

After the key is generated you can point the Toolkit to configure the environment with it by setting the `gitlab_license_file` variable to its relative path in the Ansible inventory `vars.yml` file.

## 6. Setup Static External IP

A static external IP is also required to be generated manually outside of Terraform. This will be the main IP for accessing the environment and is required to be generated separately to prevent Terraform from destroying it during a teardown and breaking any subsequent DNS entries.

The static IP can be generated depending on the Cloud Platform as follows:

- GCP - [Reserving a static external IP address](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
  - Use the default options when given a choice
  - Ensure IP has unique name
- Azure - [Create a public IP address using the Azure portal](https://docs.microsoft.com/en-us/azure/virtual-network/create-public-ip-portal?tabs=option-create-public-ip-standard-zones)
  - Attach the IP to your Resource Group and select the [*Standard* SKU](https://docs.microsoft.com/en-us/azure/virtual-network/public-ip-addresses#standard) to ensure that the allocation is static.
  - Ensure IP has unique name

Once IP is available take note of the IP address itself as it will need to be added to the specific `HAProxy` Terraform script as the `external_ips` variable under the `haproxy_external` module. You can refer to the existing environment scripts for reference, e.g. as shown [here in the 10k environment's HAProxy script](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/blob/master/terraform/10k/haproxy.tf).

After the above steps have been completed you can proceed to [building your environment](building_environments.md)
