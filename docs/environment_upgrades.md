# Upgrade Notes

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks, Data Disks, Advanced Search and more](environment_advanced.md)
- [**GitLab Environment Toolkit - Upgrade Notes**](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

The Toolkit fully supports handling GitLab upgrades for your environment - with both standard and [Zero Downtime upgrades](https://docs.gitlab.com/ee/update/zero_downtime.html) supported.

On this page we'll detail notes about performing upgrades that you should consider beforehand. **It's worth noting this guide is supplementary to the rest of the docs and it will assume this throughout.**

[[_TOC_]]

## How Upgrades Work

By design the Toolkit will perform upgrades much in the same way as the first build - any _provisioning_ changes are handled by Terraform and _configuration_ changes handled by Ansible.

Typically this should be seamless and running the same commands just as you did in the main runs should only be required to perform any GitLab upgrades.

## Use the latest version of the Toolkit

Before running any upgrades for your environment we recommend using the latest version of the Toolkit. This will ensure that the latest GitLab config is used when updating and will avoid any issues.

### Check for any Toolkit breaking or config changes

In addition to the above, when updating the Toolkit, we recommend checking the [Toolkit's release notes](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/releases) for any called out breaking or config changes to ensure no issues occur on upgrade.

### Perform Terraform Dry Runs for new Toolkit versions

Where possible we **strongly** recommend that you do Terraform dry runs whenever you have updated the Toolkit to ensure no significant unintended actions occur.

This is done simply by running `terraform plan`.

Once completed the output will show what actions are to be performed. If any actions are listed to be performed, especially destroy actions, we recommend checking these against the [release notes](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/releases) where these should be called out to ensure they are intended. If any of the actions look suspect please reach out to us via the [issue tracker](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/issues) or via the standard [support channels](https://about.gitlab.com/support/).

This is recommended as certain infrastructure changes can trigger large destroy actions that in turn can lead to the loss of the environment and data. While this is behavior from the cloud providers, every effort is made with the Toolkit to ensure this is avoided but since the consequences can be significant it's always best to do the dry run as described above out an abundance of caution.

In addition to this we'll endeavor to call out any config options that if changed could also lead to the above.

### Avoid automated Toolkit updates and Terraform Auto Approve together

With the above considerations it's worth calling out specifically that you should avoid automated Toolkit updates along with using the Terraform `--auto-approve` behavior together. This option, available with various Terraform commands such as `terraform apply`, instructs Terraform to make all changes without confirmation.

This recommendation is especially so with Production instances. If you're using the Toolkit with non production instances where a risk of data loss is acceptable then the above combination may be desirable.

## Follow GitLab Upgrade Paths

The Toolkit by default will always attempt to install the latest GitLab version unless [configured differently](environment_configure.md#gitlab-version).

However the [standard GitLab Upgrade rules still apply](https://docs.gitlab.com/ee/update/#upgrade-paths) when upgrading across multiple GitLab versions. You should refer to the docs to ensure the intended upgrade can be performed directly or if you need to upgrade to a certain version first.

## Zero Downtime Updates

For Zero Downtime Updates, the toolkit follows the [GitLab documented process](https://docs.gitlab.com/omnibus/update/README.html#zero-downtime-updates) and as such the documentation should be read and understood before proceeding with an update.

:information_source:&nbsp; As with any update process there may rarely be times where a small number of requests fail when the update is in progress. For example, when updating a primary node it can take up to a few seconds for a new leader to be elected.

Running the zero downtime update process with GET is done in the same way as building the initial environment but with a different playbook instead:

1. `cd` to the `ansible/` directory if not already there.
1. Run `ansible-playbook` with the intended environment's inventory against the `zero-downtime-update.yml` playbook

    `ansible-playbook -i environments/10k/inventory playbooks/zero_downtime_update.yml`

1. If GET is managing your Praefect Postgres instance you will need to run the following command to update this

    `ansible-playbook -i environments/10k/inventory playbooks/praefect_postgres.yml`

:information_source:&nbsp; This will cause downtime due to GET only using a single Praefect Postgres node.
  If you want to have a highly available setup, Praefect requires a third-party PostgreSQL database and will need to be updated manually.

The update process can take a couple of hours to complete and the full runtime will depend on the number of nodes in the deployment.
