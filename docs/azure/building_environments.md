# Building environment(s)

* [GitLab Performance Environment Builder - Preparing the toolkit](prep_toolkit.md)
* [**GitLab Performance Environment Builder - Building environments**](building_environments.md)

With the [toolkit prepared](prep_toolkit.md) you can proceed to building environment(s).

[[_TOC_]]

## Build environment(s)

Environments are built in two stages: [Provisioning infrastructure via Terraform](../building_environments.md#provisioning-environments-infrastructure-with-terraform) and then [Configuring GitLab via Ansible](../building_environments.md#configuring-gitlab-on-environments-with-ansible). Please refer to [Building environments](../building_environments.md) for the full guidance on how to build the environment(s).

## Shutdown Azure Environment(s)

If you don't need to use the environment(s) daily, you can save costs by [deallocating the VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/states-lifecycle). Instead of just shutting down the Operating System, Azure will also deallocate the compute resources allocated for the VM. This in turn means Azure will no longer charge you for the compute resources, and it will report the status of the VM as being in a “Stopped (Deallocated)” state.

```sh
az vm deallocate --ids $(az vm list --query "[].id" -o tsv -g <your_resource_group_name>)
```

To start up the deallocated VMs run this command:

```sh
az vm start --ids $(az vm list --query "[].id" -o tsv -g <your_resource_group_name>)
```
