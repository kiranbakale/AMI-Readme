# Considerations After Deployment - Backups, Security

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Geo, Advanced Search, Zero Downtime Updates and more](environment_advanced.md)
- [**GitLab Environment Toolkit - Considerations After Deployment - Backups, Security**](environment_post_considerations.md)

The Toolkit deploys a _base_ GitLab environment based on the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/). This is by design as the Toolkit is _one for all_ and it wouldn't be possible to cover every user's specific requirements with a general toolkit.

The goal rather is for the Toolkit to give you a good base to tweak as desired per your requirements. On this page we'll call out common considerations you may want to explore.

[[_TOC_]]

## Backups

The Toolkit doesn't configure any automated backups for the various pieces of data GitLab stores. This is due to there being numerous valid backup strategies that are available for you to consider based on your requirements.

For setting up backups in general we recommend implementing a strategy as per your requirements. Please refer to the [main GitLab documentation](https://docs.gitlab.com/ee/raketasks/backup_restore.html) on this subject and how to implement. The following however should also be noted:

- The Toolkit _does_ create a `backups` Object Storage bucket and configures GitLab to use it by default as a convenience with its Rake task. Automated backups aren't configured however so if using this Object Storage as the backup source the actual backup Rake process [should be configured as desired](https://docs.gitlab.com/ee/raketasks/backup_restore.html#configuring-cron-to-make-daily-backups).
- Object Storage buckets such as `uploads`, etc... are **not** backed up with the GitLab provided Rake tasks. It's recommended to enable backups for these buckets as per the object storage provider used.

NOTE: If using Terraform from the Toolkit it must be noted that a `terraform destroy` command will **destroy all data and lead to data loss**. Issuing this command in any situation must be considered fully.

## Security

Security is a significant area and typically is very dependent on your specific requirements.

As a general rule the Toolkit will look to use reasonable setup practices in relation to security but it's **strongly** recommended that you undertake a full review of the environment's setup to ensure it meets your requirements.

In addition to this we have [further documentation on various practices that apply to any GitLab environment that you may also want to consider](https://docs.gitlab.com/ee/security/index.html#securing-your-gitlab-installation).
