# Legacy Setups

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [**GitLab Environment Toolkit - Legacy Setups**](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

The Toolkit will aim to support the latest [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/) but will also supports some legacy setups as required.

On this page we'll detail these legacy setups. We recommend you only do these setups if you have a good working knowledge of both the Toolkit and what the specific setups involve.

[[_TOC_]]

## Gitaly Sharded

[Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/praefect.html) is recommended in the Reference Architectures from `13.9.0` onwards for its high availability and replication features. Before Cluster Gitaly was configured in a Sharded setup, where there are multiple separate Gitaly nodes that each hosted their own repo data with no HA or replication between them.

The Toolkit supports setting up a Gitaly Sharded setup if desired. This is done simply by not provisioning the Praefect nodes required in Cluster. If these nodes aren't present the Toolkit automatically assumes that the environment is using Gitaly Sharded and will configure in that way.

Note this setup is only valid for new environments. Attempting to switch an environment from using Gitaly Cluster to Sharded and vice versa will break the environment.

## Postgres 11 & Repmgr

Postgres 12 and Patroni are recommended in the Reference Architectures from `13.9.0` onwards. The previous version of Postgres, 11, is still supported in `13.x.y` versions however and the Toolkit supports deploying it.

One of the changes with Postgres 12 was the switch to Patroni over Repmgr as the default replication manager. It's worth noting that Patroni will support a Postgres 11 setup but Repmgr won't support a Postgres 12 one.

Configuring either Postgres 11 or Repmgr can be done as follows:

- Postgres 11 - Set `postgres_version` in the inventory variables to `11`, e.g. `postgres_version: 11`. Patroni or Repmgr can be used here but note the advice below on switching replication managers for existing setups.
- Repmgr - Set the `postgres_replication_manager` inventory variable to `repmgr`. This can only be used with Postgres 11.

Like Gitaly Cluster, this guidance is only for new installs. You must note the following for existing installs:

- Attempting to switch replication manage is only supported _once_ from Repmgr to Patroni. Attempting to switch from Patroni to Repmgr will **break the environment irrevocably**.
- [Switching from Postgres 11 to 12 is supported when Patroni is the replication manager](https://docs.gitlab.com/ee/administration/postgresql/replication_and_failover.html#upgrading-postgresql-major-version-in-a-patroni-cluster) but this is a manual process that must be done directly unless on a single 1k installation. Once the upgrade process is done you must remove the `postgres_version` variable from your inventory variables.
