# Building environment(s)

* [GitLab Performance Environment Builder - Preparing the toolkit](prep_toolkit.md)
* [**GitLab Performance Environment Builder - Building environments**](building_environments.md)

With the [toolkit prepared](prep_toolkit.md) you can proceed to building environment(s). Environments are built in two stages: [Provisioning infrastructure via Terraform](#provisioning-environments-infrastructure-with-terraform) and then [Configuring GitLab via Ansible](#configuring-gitlab-on-environments-with-ansible).

[[_TOC_]]

## Provisioning Environment(s) Infrastructure with Terraform

[Terraform](https://www.terraform.io/) provisions the Environment's infrastructure. It works in a unique way where each project should have its own folder and State.

1. Create the environment's Terraform directory and scripts if they don't already exist under `terraform/`. For convenience you should copy one of the existing projects and update the authentication details in the `main.tf` and `variables.tf` files to match the new GCP project.
1. `cd` to the environment's directory under `terraform/`. For this example we'll select the 10k environment - `cd terraform/10k`
1. On the intended GCP project create a Storage Bucket for storing the Terraform state if you haven't already. You can name this as you please but the name then needs to be set in the environment's `main.tf` as a backend setting. For example here is the 10k environment's [main.tf](terraform/10k/main.tf) file with backend config.
1. In the environment's Terraform directory (e.g. `terraform/10k`), start by [initializing](https://www.terraform.io/docs/commands/init.html) the environment's Terraform scripts with `terraform init`.
1. You can next optionally run `terraform plan` to view the current state of the environment and what will be changed if you proceed to apply.
1. To apply any changes run `terraform apply` and select yes
    * **Warning - running this command will likely apply changes to shared infrastructure. Only run this command if you have permission to do so.**

## Configuring GitLab on Environment(s) with Ansible

[Ansible](https://docs.ansible.com/ansible/latest/index.html) configures GitLab on an Environment's infrastructure. 

This is achieved through getting VM info via the [`gcp_compute` Dynamic Inventory source](https://docs.ansible.com/ansible/latest/plugins/inventory/gcp_compute.html) and then running Ansible Playbooks & Roles against each depending on the VM Labels set via Terraform. Unlike Terraform Ansible doesn't require separate folders per Environment but does require a small config directory for each under `ansible/inventories/`

Playbooks & Roles are structured to cover GitLab nodes respectively. E.G. There are playbooks for `gitlab-rails`, `gitaly`, etc... You can see the current list under `ansible/roles/`.

Examples of running Ansible to configure a GitLab instance can be found below. In this example we'll run all playbooks and roles against all nodes via the `all.yml` playbook:

1. `cd` to the `ansible/` directory
1. Create the Environment's inventory config under `ansible/inventories/` if it doesn't exist already. For convenience you should copy one of the existing projects inventories and update all files with the relevant info for the new environment.
1. You then use the `ansible-playbook` command to run the playbook, specifying the intended environment's inventory as well - `ansible-playbook -i inventories/10k all.yml`
    ** If you only want to run a specific playbook & role against the respective VMs you switch out `all.yml` and replace it with the intended playbook, e.g. `gitlab-rails.yml`
