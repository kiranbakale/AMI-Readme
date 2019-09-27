# GitLab Performance Environment Builder

Terraform and Ansible toolkit for building reference HA GitLab environments on Google Cloud Platform (GCP) for performance testing.

## Background

This toolkit is designed to provision and configure GitLab environments, each in their own GCP Project, that match one of our existing or soon to be created [High Availability Reference Architectures](https://docs.gitlab.com/ee/administration/high_availability/README.html#high-availability-architecture-examples)

At the time of writing we have the following environments we are currently building with this toolkit:
* [10k](https://console.cloud.google.com/home/dashboard?orgonly=true&project=gitlab-qa-10k-cd77c7&supportedpurview=organizationId)
* [20k](https://console.cloud.google.com/home/dashboard?orgonly=true&project=gitlab-qa-25k-bc38fe&supportedpurview=organizationId)
* [50k](https://console.cloud.google.com/home/dashboard?project=gitlab-qa-50k-193234)

The Toolkit consists of two industry leading tools:
* [Terraform](https://www.terraform.io/) - To provision environment infrastructure
* [Ansible](https://docs.ansible.com/ansible/latest/index.html) - To configure GitLab on the provisioned infrastructure

## Preparation
### Configuring [`git-crypt`](https://github.com/AGWA/git-crypt) for authentication

To enable authentication for both Ansible and Terraform several authentication files are provided with the toolkit. These secret files are all encrypted with [`git-crypt`](https://github.com/AGWA/git-crypt) and you'll need to either be added as a trusted user (for local use) or be provided with a symmetric key (for CI use) to unlock these as follows:

#### As a Trusted User (for local use)

To be added as a trusted user you need to generate a [GPG](https://gnupg.org/) key on your machine and send the public part to the Enablement Quality team to be added:

1. [Follow our instructions](https://docs.gitlab.com/ee/user/project/repository/gpg_signed_commits/#generating-a-gpg-key) up to step 11 on how to generate a GPG file and public key.
1. After step 11 you should have your public key in ASCII form. Contact the Enablement Quality team (e.g. on Slack at #qa-performance) where they'll take the key and add you as a trusted user.

After being added as a trusted user, you can checkout this repo and then unlock the secret files with the command `git-crypt unlock`. `git-crypt` will then automatically encrypt and decrypt secrets for you from now on.

#### With a provided symmetric key (CI use)

TBC

### Useful Resources

Each of the tools this toolkit uses need to be installed before using:
* [Terraform Install Guide](https://learn.hashicorp.com/terraform/getting-started/install.html)
* [Ansible Install Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

If you are new to any of the tools here it's worth going through the following tutorials for them:
* [Terraform GCP Tutorial](https://learn.hashicorp.com/terraform/gcp/intro)
* [Ansible Tutorial](https://www.guru99.com/ansible-tutorial.html)

## Provisioning Environment(s) Infrastructure with Terraform

Provisioning or updating an Environment's infrastructure with [Terraform](https://www.terraform.io/) is done as follows:

>>>
**[Terraform Remote State](https://learn.hashicorp.com/terraform/gcp/remote)**
**Terraform keeps a live [state](https://learn.hashicorp.com/terraform/gcp/remote) file of the environment. This is an important part of Terraform as it will refer to this to see what state the intended environment is in at the time of running. To ensure the state is correct for everyone using the tool we store it in the environment's GCP Project under a specific bucket. This should already be configured for the existing projects if not you'll need to ensure the bucket is created in GCP and then configure the respective `main.tf` file accordingly.**
>>>

1. `cd` to the intended environment's directory under `terraform/`. For this example we'll select the 10k environment - `cd terraform/10k`
1. You can first run `terraform plan` to view the current state of the environment and what will be changed if you proceed to apply.
1. To apply any changes run `terraform apply` 
    * **Warning - running this command will likely apply changes to shared infrastructure. Only run this command if you have permission to do so.**

## Configuring GitLab on Environment(s) with Ansible

We use [Ansible](https://docs.ansible.com/ansible/latest/index.html) to configure GitLab on an Environment's infrastructure. 

This is achieved through getting VM info via the [`gcp_compute` Dynamic Inventory source](https://docs.ansible.com/ansible/latest/plugins/inventory/gcp_compute.html) and then running Ansible Playbooks & Roles against each depending on the VM Labels set via Terraform:

Playbooks & Roles are structured to cover GitLab nodes respectively. E.G. There are playbooks for `gitlab-rails`, `gitaly`, etc... You can see the current list under `ansible/roles/`.

Examples of running Ansible to configure a GitLab instance can be found below. In this example we'll run all playbooks and roles against all nodes via the `all.yml` playbook:

1. `cd` to the `ansible/` directory
1. You then use the `ansible-playbook` command to run the playbook, specifying the intended environment's inventory as well - `ansible-playbook -i inventories/10k all.yml`
    ** If you only want to run a specific playbook & role against the respective VMs you switch out `all.yml` and replace it with the intended playbook, e.g. `gitlab-rails.yml`
