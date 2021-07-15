# Preparing the environment

- [**GitLab Environment Toolkit - Preparing the environment**](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Customizations](environment_advanced.md)
  - [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
  - [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)

To start using the Toolkit to build an environment you'll first need to do some preparation for the environment itself, depending on how you intend to host it. These docs assume working knowledge of the selected host provider the environment is to run on, such as a specific Cloud provider.

This page starts off with general guidance around fundamentals but then will split off into the steps for each supported specific provider. As such, you should only follow the section for your provider after the general sections.

[[_TOC_]]

## Overview

Before you begin preparing your environment there are several fundamentals that are worth calling out regardless of provider.

After reading through these proceed to the steps for your specific provider.

### Authentication

Each of the tools in this Toolkit, and even GitLab itself, all require authentication to be configured for the following:

- Direct authentication with Cloud Platform (Terraform, Ansible)
- Authentication with Cloud Platform Object Storage (Terraform, GitLab)
- SSH authentication with machines (Ansible)

Authentication is fully dependent on the provider and are detailed fully in each provider's section below.

### Terraform State

If using Terraform, one important caveat is preparing its [State](https://www.terraform.io/docs/state/index.html) file. Terraform's State is integral to how it works. For every action it will store and update the state with the full environment status each time. It then refers to this for subsequent actions to ensure the environment is always exactly as configured.

To ensure the state is correct for everyone using the toolkit we store it on the environment cloud platform in a specific bucket. This needs to be configured manually for each environment once.

Each project's State bucket is a standard one and will typically follow a simple naming convention - `<env_short_name>-terraform-state`. The name can be anything as desired though as long as it's configured subsequently in the environment's `main.tf` file.

### Static External IP

Environments also require a Static External IP to be generated manually. This will be the main IP for accessing the environment and is required to be generated separately to prevent Terraform from destroying it during a teardown and breaking any subsequent DNS entries.

## Google Cloud Platform (GCP)

### 1. GCloud CLI

We recommend installing GCP's command line tool, `gcloud` as per the [official instructions](https://cloud.google.com/sdk/install). While this is not strictly required it makes authentication for Terraform and Ansible more straightforward on workstations along with numerous tools to help manage environments directly.

### 2. Create GCP Project

Each environment is recommended to have its own project on GCP for various reasons such as ensuring there's no conflicts, avoiding shared firewall rule changes / quota limits, etc...

Existing projects can also be used but this should be checked with the Project's stakeholders as this will affect things such as total CPU quotas, etc...

### 3. Setup Provider Authentication - GCP Service Account

Authentication with GCP directly is done with a [Service Account](https://cloud.google.com/iam/docs/understanding-service-accounts), which is required by both Terraform and Ansible.

A Service Account is created as follows if you're an admin:

- Head to the [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page. Be sure to check that the correct project is selected in the dropdown at the top of the page.
- Proceed to create an account with a descriptive name like `gitlab-qa` and give it the [IAM roles](https://cloud.google.com/iam/docs/granting-changing-revoking-access#granting-console) of `Compute Instance Admin (v1)`, `Kubernetes Engine Admin`, `Storage Admin` and `Service Account User`.
- On the last page there will be the option to generate a key. Select to do so with the `JSON` format and save it locally with a reasonable naming convention like `serviceaccount-<project-name>.json`, e.g. `serviceaccount-10k.json`, as in GCP the key will have a default name that's unclear. This key will passed to both Terraform and Ansible later.
  - The [`keys`](../keys) directory in this project is provided as a central place to store all of your keys. It's automatically configured in `.gitignore` to not have its contents included with any Git Pushes if you desired to have your own copy of this repo.
- Finish creating the user

### 4. Setup SSH Authentication - SSH OS Login for GCP Service Account

In addition to creating the Service Account and saving the key we need to also setup [OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access) for the account to enable SSH access to the created VMs on GCP, which is required by Ansible. This is done as follows:

- [Generate an SSH key pair](https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair) and store it in the [`keys`](../keys) directory.
- With the `gcloud` command set it to point at your intended project - `gcloud config set project <project-id>`
  - Note that you need the project's [ID](https://support.google.com/googleapi/answer/7014113?hl=en) here and not the name. This can be seen on the home page for the project.
- Now login as the Service Account user via its key created in the last step - `gcloud auth activate-service-account --key-file=serviceaccount-<project-name>.json`
- Proceed to add the project's public SSH key to the account - `gcloud compute os-login ssh-keys add --key-file=<SSH key>.pub`
- Next you need to get the actual Service Account SSH username. This is in the format of `sa_<ID>`. The ID can be obtained with the following command - `echo "sa_$(gcloud iam service-accounts describe <service_account_username>@<project-id>.iam.gserviceaccount.com --format='value(uniqueId)')"`. Take a note of this username for for use with Ansible later in these docs.
- Finish with switching gcloud back to be logged in as your account `gcloud config set account <account-email-address>`, where the email address to use would be your own.

SSH access should now be enabled on the Service Account and this will be used by Ansible to SSH login to each VM. More info on OS Login and how it's configured can be found in this [blog post by Alex Dzyoba](https://alex.dzyoba.com/blog/gcp-ansible-service-account/).

That's all that's required for now. Later on in this guide we'll configure the Toolkit to use the key for accessing machines.

### 5. Setup Terraform State Storage Bucket - GCP Cloud Storage

Create a standard [GCP storage bucket](https://cloud.google.com/storage/docs/creating-buckets) on the intended environment's project for its Terraform State. Give this a meaningful name such as `<env_short_name>-terraform-state`.

After the Bucket is created this is all that's required for now. We'll configure Terraform to use it later in these docs.

### 6. Create Static External IP - GCP

A static IP can be generated in GCP as follows:

- Reserve a static external IP address in your project [as detailed in the GCP docs](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
- Use the default options when given a choice
- Ensure IP has unique name

Once the IP is available take note of it for later.

## Amazon Web Services (AWS)

### 1. Setup Provider Authentication - Environment Variables

Authentication with AWS directly can be done in [various ways](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).

The most straightforward of these options that work with both Terraform and AWS is to create access keys for your user and then set them via the Environment Variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` respectively.

To create an access key for your user follow [the official docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey). Once created save these in a secure location and then set each key to the respective environment variable as shown above in any shell or CI job you're looking to run the Toolkit.

### 2. Setup SSH Authentication - AWS

SSH authentication for the created machines on AWS will require an SSH key.

This is straightforward with AWS. All that's required is for a key to be created and then for this to be accessible for the Toolkit to handle the rest:

- [Generate an SSH key pair](https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair) and store it in the [`keys`](../keys) directory.

It is also possible to use an existing SSH key pair, but it is recommended to use a new key to avoid any potential security implications.

That's all that's required for now. Later on in this guide we'll configure the Toolkit to use this key for adding into the AWS machines as well as accessing them.

### 3. Setup Terraform State Storage - AWS S3

Create a standard [AWS storage bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html) on the intended environment's project for its Terraform State. Give this a meaningful name such named as `<env_short_name>-terraform-state`.

After the Bucket is created this is all that's required for now. We'll configure Terraform to use it later in these docs.

### 4. Create Static External IP - AWS Elastic IP Allocation

A static IP, AKA an Elastic IP, can be generated in AWS as follows:

- Reserve a static external IP address in your project [as detailed in the AWS docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html#using-instance-addressing-eips-allocating)
- Use the default options when given a choice

Once the IP is available take note of its allocation ID for later.

## Azure

### 1. Create Azure Resource Group

Each environment is recommended to have its own [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group) on Azure. Create a group following the [official guide](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups). When given a choice using the default options is fine.

Existing resource groups can also be used but this should be checked with the Group's stakeholders as this will affect things such as total CPU quotas, etc...

### 2. Setup Provider Authentication - Azure

Authentication with Azure directly can be done in [various ways](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure).

It's recommended to use either a Service Principal(with [Client Certificate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_certificate) or [Client Secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)) or [Managed Service Identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/managed_service_identity) when running Terraform non-interactively (such as when running Terraform in a CI server) - and authenticating using the [Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli) when running Terraform locally.

Once you have selected the authentication method and obtained the credentials you may export them as Environment Variables following the Terraform instructions for the specific authentication type.

### 3. Setup SSH Authentication - Azure

SSH authentication for the created machines on Azure will require an admin username and an SSH key.

First think of an admin username that will be used for SSH connection to the Azure's virtual machines. Take a note of this name, it will be needed later in these docs.

All that's required for an SSH key is to be created and then for this to be accessible for the Toolkit to handle the rest:

- [Generate an SSH key pair](https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair) and store it in the `keys` directory.

It is also possible to use an existing SSH key pair, but it is recommended to use a new key to avoid any potential security implications.

That's all that's required for now. Later on in this guide we'll configure the Toolkit to use the admin username and the key for adding into the Azure machines as well as accessing them.

### 4. Setup Terraform State Storage - Azure Blob Storage

Create a [storage account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create) that will contain all of your Azure Storage data objects. Take a note of its name and [access key](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-keys-manage) for later.

Then create a standard [Azure blob container](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-portal) on the intended environment's storage account for its Terraform State. Give this a meaningful name such as `<env_short_name>-terraform-state`.

After the container is created this is all that's required for now. We'll configure Terraform to use it later in these docs.

### 5. Create Static External IP - Azure

A static IP can be generated in Azure as follows:

- Reserve a static external IP address in your resource group [as detailed in the Azure docs](https://docs.microsoft.com/en-us/azure/virtual-network/create-public-ip-portal?tabs=option-create-public-ip-standard-zones)
- Make sure to select the *[Standard SKU](https://docs.microsoft.com/en-us/azure/virtual-network/public-ip-addresses#standard)* to ensure that the allocation is static 

Once the IP is available take note of its name for later.

## Next Steps 

After the above steps have been completed you can proceed to [Provisioning the environment with Terraform](environment_provision.md).
