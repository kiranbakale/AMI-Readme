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
### Download Service Account Keys (WIP)

To be able to use both Terraform and Ansible locally against GCP you'll need to download a [Service Account Key](https://cloud.google.com/iam/docs/understanding-service-accounts) to authenticate.

These keys should be already created for our reference environment projects and can be found under each project's secrets bucket. For the projects you want to access head to each of their secrets bucket and proceed to download the Service Account Key to this project's root (will following the naming convention of `serviceaccount-<project>.json`).

Currently we have 3 projects that have keys as follows:
* [10k](https://storage.cloud.google.com/gitlab-gitlab-qa-10k-secrets/serviceaccount-10k.json)
* [20k](https://storage.cloud.google.com/gitlab-gitlab-qa-25k-secrets/serviceaccount-25k.json)
* [50k](https://storage.cloud.google.com/gitlab-gitlab-qa-50k-secrets/serviceaccount-50k.json)

The toolkit is already configured to access the keys as they are named in the root on this project. Note that this may change in the future as we update best practices on handling authentication.

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

This is achieved through getting VM info via the [`gcp_compute` Dynamic Inventory source](https://docs.ansible.com/ansible/latest/plugins/inventory/gcp_compute.html) (using the same Service Account key as before) and then running Ansible Playbooks & Roles against each depending on the VM Labels set via Terraform:

Playbooks & Roles are structured to cover GitLab nodes respectively. E.G. There are playbooks for `gitlab-rails`, `gitaly`, etc... You can see the current list under `ansible/roles/`.

Examples of running Ansible to configure a GitLab instance can be found below. In this example we'll run all playbooks and roles against all nodes via the `all.yml` playbook:

1. `cd` to the `ansible/` directory
1. You then use the `ansible-playbook` command to run the playbook, specifying the intended environment's inventory as well - `ansible-playbook -i inventories/10k all.yml`
    ** If you only want to run a specific playbook & role against the respective VMs you switch out `all.yml` and replace it with the intended playbook, e.g. `gitlab-rails.yml`
