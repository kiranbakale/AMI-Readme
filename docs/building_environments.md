# Building environment(s)

* [GitLab Environment Toolkit - Preparing the toolkit](prep_toolkit.md)
* [**GitLab Environment Toolkit - Building environments**](building_environments.md)
* [GitLab Environment Toolkit - Building an environment with Geo](building_geo_environments.md)

With the [Toolkit prepared](prep_toolkit.md) you can proceed to build your environment(s). Environments are built in two stages as detailed below:

[[_TOC_]]

## 1. Provisioning Environment Machines and Infrastructure with Terraform

[Terraform](https://www.terraform.io/) provisions the Environment's machines and infrastructure. It works in a unique way where each environment should have its own folder and State.

1. Create the environment's Terraform directory and scripts if they don't already exist under `terraform/`. For convenience you should copy one of the existing projects for the target Cloud Provider and update the authentication details in the `main.tf` and `variables.tf` files accordingly.
1. `cd` to the environment's directory under `terraform/`. For this example we'll select the 10k environment - `cd terraform/10k`
1. On the intended Cloud Provider setup a Storage Bucket as [detailed earlier in the docs](prep_toolkit.md#3-prepare-terraform-state-bucket-on-cloud-platform) for storing the Terraform state if you haven't already. You can name this as you please but the name then needs to be set in the environment's `main.tf` as a backend setting. For example here is the 10k environment's [main.tf](terraform/10k/main.tf) file with backend config.
1. In the environment's Terraform directory (e.g. `terraform/10k`), start by [initializing](https://www.terraform.io/docs/commands/init.html) the environment's Terraform scripts with `terraform init`.
1. You can next optionally run `terraform plan` to view the current state of the environment and what will be changed if you proceed to apply.
1. To apply any changes run `terraform apply` and select yes
    * **Warning - running this command will likely apply changes to shared infrastructure. Only run this command if you have permission to do so.**

## 2. Configuring GitLab on the Environment with Ansible

[Ansible](https://docs.ansible.com/ansible/latest/index.html) configures GitLab on an Environment's infrastructure.

This is achieved through getting VM info via [Dynamic Inventories](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html) ([GCP](https://docs.ansible.com/ansible/latest/plugins/inventory/gcp_compute.html), [Azure](https://docs.ansible.com/ansible/latest/collections/azure/azcollection/azure_rm_inventory.html)) and then running Ansible Playbooks & Roles against each depending on the VM Labels set in Terraform. Unlike Terraform Ansible doesn't require separate folders per Environment but does require a small config directory for each under `ansible/inventories/`.

The approach with this Toolkit for Ansible is to have a separate Playbook and Role for each GitLab component respectively that in turn corresponds to the target GitLab node.
For example, there are playbooks for `gitlab-rails`, `gitaly`, etc... You can see the current list under `ansible/roles/`. Do note though we have other Playbooks that cover additional tasks such as apply a GitLab License, configuring Advanced Search and so on.

The Toolkit provides two ways of running Ansible through its Playbooks - through its native `ansible-playbook` command or optionally through a convenience script, `ansible-deployer`, that we've created that will attempt to run through all of the playbooks quicker through parallelization.

### Running with ansible-playbook

The `all.yml` playbook is the entry point for running Ansible on every machine. It's a "runner" playbook in that it will go through each specific component's playbook in order. It can be run with `ansible-playbook` as follows:

1. `cd` to the `ansible/` directory
1. Create the Environment's inventory config under `ansible/inventories/` if it doesn't exist already. For convenience you should copy one of the existing projects inventories and update all files with the relevant info for the new environment.
1. Run `ansible-playbook` with intended environment's inventory against the `all.yml` playbook - `ansible-playbook -i inventories/10k all.yml`
    ** If you only want to run a specific playbook & role against the respective VMs you can switch out `all.yml` and replace it with the intended playbook, e.g. `gitlab-rails.yml`

### Running with ansible-deployer (optional)

The main difference with using the `ansible-deployer` script is that this command will run multiple playbooks in parallel where possible while maintaining the required run order. The script can either run all of the playbooks by default or a custom list as passed via the `-p` flag. It should be noted that due to the script running tasks in parallel, if any issues arise during setup then the playbooks would be better run sequentially via the [Using ansible-playbook](using-ansible-playbook) steps to help debug the problem(s).

The script can be run as follows:

1. Create the Environment's inventory config under `ansible/inventories/` if it doesn't exist already. For convenience you should copy one of the existing projects inventories and update all files with the relevant info for the new environment.
1. You then use the `ansible-deployer` command to run the playbook, specifying the intended environment's inventory just the same as `ansible-playbook` - `./bin/ansible-deployer -i 10k`

Due to running multiple commands in parallel the stdout of the ansible runner can get very messy, to alleviate this issue the stdout is suppressed and each playbook will create its own log file in `logs`.

With the above steps completed you should have a running environment that's accessible at the Static IP you defined earlier in the docs.

## Environment Notes

In this section you'll find various notes on running the environment(s) you've created.

### Switching the Environment On and Off

To save costs you find it useful to switch environment(s) on and off again as required. We recommend this is done via the native Cloud Platform UI or tools. As a further note for Azure you can go further if the environment is expected to not be used often by [Deallocating the VMs](https://support.hostway.com/hc/en-us/articles/360001059850-Deallocate-Azure-Virtual-Machines) to save on costs further.

When turning off the environment you may want to keep the HAProxy External and Monitor nodes on to look at monitoring data from previous test runs, etc...
