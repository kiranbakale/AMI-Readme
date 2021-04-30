# Preparing the environment

- [**GitLab Environment Toolkit - Preparing the environment**](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Customizations](environment_advanced.md)
  - [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)

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

Existing projects can also be used but this should be checked with the Project's stakeholders as this will effect things such as total CPU quotas, etc...

### 3. Setup Provider Authentication - GCP Service Account

Authentication with GCP directly is done with a [Service Account](https://cloud.google.com/iam/docs/understanding-service-accounts), which is required by both Terraform and Ansible.

A Service Account is created as follows if you're an admin:

- Head to the [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page. Be sure to check that the correct project is selected in the dropdown at the top of the page.
- Proceed to create an account with a descriptive name like `gitlab-qa` with the `Compute OS Admin Login`, `Editor` and `Kubernetes Engine Admin` roles.
- On the last page there will be the option to generate a key. Select to do so with the `JSON` format and save it with a reasonable naming convention like `serviceaccount-<project-name>.json`, e.g. `serviceaccount-10k.json`. This key will passed to both Terraform and Ansible later.
  - The [`keys`](../keys) directory in this project is provided as a central place to store all of your keys. It's automatically configured in `.gitignore` to not have its contents included with any Git Pushes if you desired to have your own copy of this repo.
- Finish creating the user

### 4. Setup SSH Authentication - SSH OS Login for GCP Service Account

In addition to creating the Service Account and saving the key we need to also setup [OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access) for the account to enable SSH access to the created VMs on GCP, which is required by Ansible. This is done as follows:

- [Generate an SSH key pair](https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair) and store it in the [`keys`](../keys) directory.
- With the `gcloud` command set it to point at your intended project - `gcloud config set project <project-id>`
  - Note that you need the project's [ID](https://support.google.com/googleapi/answer/7014113?hl=en) here and not the name. This can be seen on the home page for the project.
- Now login as the Service Account user via its key created in the last step - `gcloud auth activate-service-account --key-file=serviceaccount-<project-name>.json`
- Proceed to add the project's public SSH key to the account - `gcloud compute os-login ssh-keys add --key-file=<SSH key>.pub`
- Next you need to get the actual Service Account SSH username. This is in the format of `sa_<ID>`. The ID can be obtained with the following command - `gcloud iam service-accounts describe gitlab-qa@<project-id>.iam.gserviceaccount.com --format='value(uniqueId)'`. Take a note of this ID for for use with Ansible later in these docs.
- Finish with switching gcloud back to be logged in as your account `gcloud config set account <account-email-address>`

SSH access should now be enabled on the Service Account and this will be used by Ansible to SSH login to each VM. More info on OS Login and how it's configured can be found in this [blog post by Alex Dzyoba](https://alex.dzyoba.com/blog/gcp-ansible-service-account/).

That's all that's required for now. Later on in this guide we'll configure the Toolkit to use the key for accessing machines.

### 5. Setup Terraform State Storage Bucket - GCP Cloud Storage

Create a standard [GCP storage bucket](https://cloud.google.com/storage/docs/creating-buckets) on the intended environment's project for its Terraform State. Give this a meaningful name such named as `<env_short_name>-terraform-state`.

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

To create an access for your user follow the official docs [here](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey). Once created save these in a secure location and then set each key to the respective environment variable as shown above in any shell or CI job you're looking to run the Toolkit.

### 2. Setup SSH Authentication - AWS

SSH authentication for the created machines on AWS will require an SSH key.

This is straightforward with AWS. All that's required is for a key to be created and then for this to be accessible for the Toolkit to handle the rest:

- [Generate an SSH key pair](https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair) and store it in the [`keys`](../keys) directory.

That's all that's required for now. Later on in this guide we'll configure the Toolkit to use this key for adding into the AWS machines as well as accessing them.

### 3. Setup Terraform State Storage - AWS S3

Create a standard [AWS storage bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html) on the intended environment's project for its Terraform State. Give this a meaningful name such named as `<env_short_name>-terraform-state`.

After the Bucket is created this is all that's required for now. We'll configure Terraform to use it later in these docs.

### 4. Create Static External IP - AWS Elastic IP Allocation

A static IP, AKA an Elastic IP, can be generated in AWS as follows:

- Reserve a static external IP address in your project [as detailed in the AWS docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html#using-instance-addressing-eips-allocating)
- Use the default options when given a choice

Once the IP is available take note of its allocation ID for later.

## Azure (Coming Soon)

<img src="https://gitlab.com/uploads/-/system/project/avatar/1304532/infrastructure-avatar.png" alt="Under Construction" width="100"/>

## Next Steps 

After the above steps have been completed you can proceed to [Provisioning the environment with Terraform](environment_provision.md).
