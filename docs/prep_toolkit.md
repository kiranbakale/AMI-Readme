# Preparing the toolkit

* [**GitLab Performance Environment Builder - Preparing the toolkit**](prep_toolkit.md)
* [GitLab Performance Environment Builder - Building environments](building_environments.md)

Before building environments you'll need to do some preparation for the toolkit both locally as well as on GCP.

[[_TOC_]]

## Create Google Cloud Platform Project

Each environment needs to have its own project on GCP. A project can be requested from the GitLab Infrastructure team by [raising an issue on their tracker](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues) with the `group_project` template.

## Install Terraform, Ansible and GCloud

Each of the tools in this toolkit uses need to be installed beforehand. You can choose how to install both as desired as long as they're reachable on the command line after. The official installation docs for each are as follows:
* [Terraform Install Guide](https://learn.hashicorp.com/terraform/getting-started/install.html)
  * **Make sure to install the specific Terraform version as stated in the environment's `main.tf` file**. Terraform requires the version to match for all people using it. Quality team will periodically update this version after testing. Errors will be thrown by Terraform when the install version being used doesn't match what its shared State file expects.
* [Ansible Install Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* [GCloud Install Guide](https://cloud.google.com/sdk/install)

If you are new to any of the tools here it's also worth going through some tutorials to learn the basics. Some examples of good tutorials are:
* [Terraform GCP Tutorial](https://learn.hashicorp.com/terraform/gcp/intro)
* [Ansible Tutorial](https://www.guru99.com/ansible-tutorial.html)

### Prepare Terraform State Bucket on GCP

One additional specific step is required for Terraform - preparing it's [State](https://www.terraform.io/docs/state/index.html). Terraform's State is integral to how it works. For every action it will store and update the state with the full environment status each time. It then refers to this for subsequent actions to ensure the environment is always exactly as configured.

To ensure the state is correct for everyone using the tool we store it in the environment's GCP Project under a specific bucket. This needs to be configured manually by us for each environment once.

Each project's State bucket is a standard GCP one and will typically follow a simple naming convention - `<env_short_name>-terraform-state`. The name can be anything as desired though as long as it's configured subsequently in the environment's `main.tf` file.

To summarize the above as steps:

1. Create a standard GCP storage bucket on the intended environment's project for its Terraform State named as `<env_short_name>-terraform-state`. For example the 10k's State bucket is named `10k-terraform-state`.
1. Configure the environment's `main.tf` to point to and use this bucket as Terraform's State location. For example here is the 10k environment's [main.tf](terraform/10k/main.tf) file with backend config.
    * If the Terraform config files are yet to created for the environment then this can wait until the next stage where this will be done.

### Install Ansible Dependencies

Ansible requires some dependencies to be installed based on how we use it. You'll need to install python package dependencies on your machine along with some community roles from [Ansible Galaxy](https://galaxy.ansible.com/home) that allow for convenient deployment of some third party applications.

To do this you only have to run the following before running Ansible:

1. `cd` to the `ansible/` directory
1. First install the python packages via `pip install -r requirements/ansible-python-packages.txt`.
    * Note it's expected you already have Python and its package manager pip installed. Additionally you may have the Python3 version of pip installed, `pip3`, and you should replace accordingly.
1. Next, run the following command to install the roles - `ansible-galaxy install -r requirements/ansible-roles.yml`
1. Note that if you're on a Mac OS machine you also need to install `gnu-tar` - `brew install gnu-tar`

## Key Generation

The builder requires several authentication keys to be generated and available in the [`keys`](../keys) directory to build the environments. The keys required are:

* [GCP Service Account](https://console.cloud.google.com/iam-admin/serviceaccounts) key
* SSH key for [GCP OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access)
* [GitLab license](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee) key (Optional)

In this section we detail how to generate each.

### GCP Service Account key

Each environment should have its own project on GCP. Terraform and Ansible both require a [Service Account](https://cloud.google.com/iam/docs/understanding-service-accounts) to be created. If this is a new project without a Service Account then you can create one as follows if you're an admin:

* Head to the [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page. Be sure to check that the correct project is selected in the dropdown at the top of the page.
* Proceed to create an account with a descriptive name like `gitlab-qa` with the `Compute OS Admin Login`, `Editor` and `Kubernetes Engine Admin` roles.
* On the last page there will be the option to generate a key. Select to do so with the `JSON` format and save it a reachable location that will be configured in both of the tools later.
  * If this is for a live environment the key should be added to the [`keys`](../keys) directory in this project with a reasonable naming convention like `serviceaccount-<project-name>.json`, e.g. `serviceaccount-10k.json`.
* Finish creating the user

Once the key has been saved you need to configure both Terraform and Ansible to use it as follows:
* Terraform - For each environment there are two places the Service Account key location needs to be configured, one for the State object storage and the other for the main GCP access. Configure the location in the `main.tf` and `variables.tf` files with the relative path. For `variables.tf` the path should be saved under the variable name of `credentials_file`.
  * As an example you can refer to the current environment projects. For example the 10k environment's [`main.tf`](../terraform/10k/main.tf) and [`variables.tf`](../terraform/10k/variables.tf) files.
* Ansible - The files relative path location only needs to be configured once for each environment in the inventory file under the variable name `service_account_file`.
  * For example, look to the 10k Ansible inventory file, [`10k.gcp.yml`](../ansible/inventories/10k/10k.gcp.yml).

### Configuring SSH OS Login for Service Account

In addition to creating the Service Account and saving the key we need to also setup [OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access) for the account to enable SSH access to the created VMs on GCP, which is required by Ansible. This is done as follows:

* Generate an SSH key pair and store it in the [`keys`](../keys) directory.
* With the `gcloud` command set it to point at your intended project - `gcloud config set project <project-id>`
  * Note that you need the project's ID here and not the name. This can be seen on the home page for the project.
* Now login as the Service Account user via it's key created in the last step - `gcloud auth activate-service-account --key-file=serviceaccount-<project-name>.json`
* Proceed to add the project's public SSH key to the account - `gcloud compute os-login ssh-keys add --key-file=<SSH key>.pub`
* Next you need to get the actual Service Account SSH username for Ansible. This is in the format of `sa_<ID>`. The ID can be obtained with the following command - `gcloud iam service-accounts describe gitlab-qa@<project-id>.iam.gserviceaccount.com --format='value(uniqueId)'`. Take the ID from this command and add it to the Ansible inventory `vars.yml` file under `ansible_user` in the format `sa_<ID>`.
* For the private key this also needs to be configured in the Ansible inventory `vars.yml` by setting `ansible_ssh_private_key_file` to the relative path of the private key file.
* Finish with switching gcloud back to be logged in as your account `gcloud config set account <account-email-address>`

SSH access should now be enabled on the Service Account and this will be used by Ansible to SSH login each VM. More info on OS Login and how it's configured can be found [here](https://alex.dzyoba.com/blog/gcp-ansible-service-account/).

### GitLab License key

A GitLab License key (Ultimate) may also be required depending on the GitLab functionality you're looking to have on the environment. The builder considers this to be optional though and will work without one.

To generate a key as a developer refer to the [handbook](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee). An Ultimate license key is recommended to enable all features.

After the key is generated you can point the builder to configure the environment with it by setting the `gitlab_license_file` variable to its relative path in the Ansible inventory `vars.yml` file.

## Static External IP

A static external IP is also required to be generated manually outside of Terraform. This will be the main IP for accessing the environment and is required separately due to Terraform needing full control over everything it creates so in the case of a teardown it would destroy this IP and break any DNS entries.

New GCP projects may already have one IP defined by default that you can use for this purpose. If there isn't one then a new IP can be generated via the [External IP Addresses](https://console.cloud.google.com/networking/addresses/list?project=gitlab-qa-25k-bc38fe) page as required.

Once either the default or newly created IP is found take note of the IP address itself as it will need to be added to the specific `HAProxy` Terraform script as the `external_ips` variable under the `haproxy_external` module. You can refer to the existing environment scripts for reference, e.g. as shown [here in the 10k environment's HAProxy script](https://gitlab.com/gitlab-org/quality/performance-environment-builder/blob/master/terraform/10k/haproxy.tf).
