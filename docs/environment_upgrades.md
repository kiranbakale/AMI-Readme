# Upgrades (Toolkit, Environment)

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md)
- [**GitLab Environment Toolkit - Upgrades (Toolkit, Environment)**](environment_upgrades.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

When discussing upgrades there's not only the Environment to consider but also the Toolkit itself.

On this page we'll detail how both work. **It's worth noting this guide is supplementary to the rest of the docs, and it will assume this throughout.**

[[_TOC_]]

## Toolkit Upgrades

Before running any upgrades for your environment we recommend using the latest version of the Toolkit. This will ensure that the latest GitLab config is used when updating and will avoid any issues.

When updating the Toolkit, we recommend checking the [Toolkit's release notes](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/releases) for any called out breaking or config changes to ensure no issues occur on upgrade.

In addition to the above please be aware of the following guidance also:

### Perform Terraform Dry Runs for new Toolkit versions

Where possible we **strongly** recommend that you do Terraform dry runs whenever you have updated the Toolkit to ensure no significant unintended actions occur.

This is done simply by running `terraform plan`.

Once completed the output will show what actions are to be performed. If any actions are listed to be performed, especially destroy actions, we recommend checking these against the [release notes](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/releases) where these should be called out to ensure they are intended. If any of the actions look suspect please reach out to us via the [issue tracker](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/issues) or via the standard [support channels](https://about.gitlab.com/support/).

This is recommended as certain infrastructure changes can trigger large destroy actions that in turn can lead to the loss of the environment and data. While this is behaviour from the cloud providers, every effort is made with the Toolkit to ensure this is avoided but since the consequences can be significant it's always best to do the dry run as described above out an abundance of caution.

In addition to this we'll endeavour to call out any config options that if changed could also lead to the above.

### Avoid automated Toolkit updates and Terraform Auto Approve together

With the above considerations it's worth calling out specifically that you should avoid automated Toolkit updates along with using the Terraform `--auto-approve` behaviour together. This option, available with various Terraform commands such as `terraform apply`, instructs Terraform to make all changes without confirmation.

This recommendation is especially so with Production instances. If you're using the Toolkit with non production instances where a risk of data loss is acceptable then the above combination may be desirable.

## Environment Upgrades

The Toolkit fully supports handling GitLab upgrades for your environment - with both [standard](https://docs.gitlab.com/ee/update/with_downtime.html) and [Zero Downtime upgrades](https://docs.gitlab.com/ee/update/zero_downtime.html) supported.

By design the Toolkit will perform upgrades much in the same way as the first build - any _provisioning_ changes are handled by Terraform and _configuration_ changes handled by Ansible.

Typically, this should be seamless and running the same commands just as you did in the main runs should only be required to perform any GitLab upgrades but be aware of the guidance below as applicable.

### Follow GitLab Upgrade Paths

The Toolkit by default will always attempt to install the latest GitLab version unless [configured differently](environment_configure.md#repository).

However, the [standard GitLab Upgrade rules still apply](https://docs.gitlab.com/ee/update/#upgrade-paths) when upgrading across multiple GitLab versions. You should refer to the docs to ensure the intended upgrade can be performed directly or if you need to upgrade to a certain version first.

### Zero Downtime Updates

For Zero Downtime Updates, the Toolkit translates the [documented manual process](https://docs.gitlab.com/ee/update/zero_downtime.html) to achieve the same effect as much as possible.

:information_source:&nbsp; Note that Zero Downtime Updates are **not available** for Cloud Native Hybrid environments as they aren't supported in the [GitLab Charts](https://docs.gitlab.com/charts/installation/upgrade.html).

It should be noted that achieving true Zero Downtime during an update is difficult and involving. There are various ways to approach this, all with pros and cons, and typically in most cases there will always be at least very small moments of downtime depending on that approach.

The Toolkit, being an automative solution, can't perform all the same actions a manual process can do such as removing nodes from load balancers as custom load balancers are supported. It therefore takes the approach of depending on existing automatic mechanisms in the environment setup such as load balancing and failovers to achieve the same effect in practice. In rigorous testing, it's been found this approach has minimal downtime while being faster to achieve.

At a high level the Toolkit aims to run the exact same actions for each component node it does normally but in sequential order. This ensures all supporting actions needed for components, such as OS package handling, are performed as well. It will also avoid components, depending on the environment, that aren't HA by default such as HAProxy, NFS or Praefect Postgres ([which is only supported in a single node setup with Omnibus at this time](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#praefect-postgresql)) as this would cause downtime - These need to be updated separately in a maintenance period.

Running the zero downtime update process with the Toolkit is done in the same way as building the initial environment but with a different playbook instead:

1. `cd` to the `ansible/` directory if not already there.
1. Run `ansible-playbook` with the intended environment's inventory against the `zero-downtime-update.yml` playbook

    `ansible-playbook -i environments/10k/inventory playbooks/zero_downtime_update.yml`

1. If you have a Praefect Postgres instance deployed via the Toolkit, you will need to run the following command to update it _with_ downtime:

    `ansible-playbook -i environments/10k/inventory playbooks/praefect_postgres.yml`

1. If you have HAProxy load balancers deployed via the Toolkit, you will need to run the following command to update them _with_ downtime:

    `ansible-playbook -i environments/10k/inventory playbooks/haproxy.yml`

1. If you are using OpenSearch deployed via the Toolkit, you will need to run the following command to update it _with_ downtime:

    `ansible-playbook -i environments/10k/inventory playbooks/opensearch.yml`

The update process can take a couple of hours to complete, and the full runtime will depend on the number of nodes in the deployment.

## OS Upgrades

OS version upgrades should be handled directly and follow the standard process for each OS, such as via `apt` for Ubuntu. Refer to the OS's docs for more info.

The Toolkit can't handle OS upgrades for you as they typically involve inputs and require restarts.

### Avoid Changing Machine OS Image

For VMs on Cloud Providers, **{- you should not change the Machine OS Image in Terraform -}** ([GCP](environment_provision.md#configure-machine-os-image-gcp), [AWS](environment_provision.md#configure-machine-os-image-aws), [Azure](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_provision.md#configure-machine-os-image-azure)) to try and upgrade the OS on the machine.

In Cloud Providers selecting a Machine OS image is effectively the same as selecting the base disk of a VM and making a change to this will trigger the Cloud Provider to remove the VM and create it anew with the new base this leading to potential data loss.
