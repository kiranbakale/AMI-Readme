# Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [**GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)**](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Custom Config, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)

The Toolkit supports using alternative sources for select components, such as cloud services or custom servers, instead of deploying them directly. This is supported for the Load Balancer(s), PostgreSQL and Redis components as follows:

- Cloud Services - The Toolkit supports both _provisioning_ and _configuration_ for environments to use.
- Custom Servers - For servers, provided by users, the Toolkit supports the _configuration_ for environments to use.

On this page we'll detail how to setup the Toolkit to provision and/or configure these alternatives. **It's also worth noting this guide is supplementary to the rest of the docs and it will assume this throughout.**

[[_TOC_]]

## Overview

It can be more convenient to use an alternative source for select components rather than having to manage them more directly. For example, cloud services have built in HA and don't require instance level maintenance.

Several components of the GitLab setup can be switched to a cloud service or custom server:

- [Load Balancers](https://docs.gitlab.com/ee/administration/load_balancer.html) - [AWS ELB](https://aws.amazon.com/elasticloadbalancing/), _Custom_
- [PostgreSQL](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#provide-your-own-postgresql-instance) - [AWS RDS](https://aws.amazon.com/rds/postgresql/), _Custom_
- [Redis](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#providing-your-own-redis-instance) - [AWS Elasticache](https://aws.amazon.com/elasticache/redis/), _Custom_

:information_source:&nbsp; Support for more services is ongoing. Unless specified otherwise the above is the current supported services by the Toolkit.

## Load Balancers

The Toolkit supports select provisioning and/or configuring Load Balancer(s) that GitLab requires.

:information_source:&nbsp; Load Balancer service support will continue to expand in the future. Custom load balancers are also supported.

When using an alternative Load Balancer the following changes apply when deploying via the Toolkit (depending on the load balancer):

Internal:

- HAProxy Internal node no longer needs to be provisioned via Terraform
- Internal Load Balancer host name in Ansible is set to the Load Balancer host as given by the service

Head to the relevant section(s) below for details on how to provision and/or configure.

### Provisioning with Terraform

Provisioning the alternative Load Balancer(s) via cloud services is handled directly by the relevant Toolkit module. As such, it only requires some different config in your Environment's config file (`environment.tf`).

Like the main provisioning docs there are sections for each supported provider on how to achieve this. Follow the section for your selected provider and then move onto the next step.

#### AWS ELB

##### Internal (NLB)

The Toolkit supports provisioning an AWS NLB service as the Internal Load Balancer with everything GitLab requires set up.

The variable(s) for this service start with the prefix `elb_internal_*` and should replace any previous `haproxy_internal_*` settings. The available variable(s) are as follows:

- `elb_internal_create` - Create the Internal Load Balancer service. Defaults to `false`.

To set up a standard AWS NLB service for the Internal Load Balancer it should look like the following in your `environment.tf` file:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  [...]

  elb_internal_create = true
}
```

Once the variables are set in your file you can proceed to provision the service as normal. Note that this can take several minutes on AWS's side.

Once provisioned you'll see a new output at the end of the process - `elb_internal_host`. This contains the hostname for the Load Balancer that then needs to be passed to Ansible to configure. Take a note of this hostname for the next step.

### Configuring with Ansible

Configuring GitLab to use alternative Load Balancer(s) with Ansible is the same regardless of its origin. All that's required is additional config in your [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`) to point the Toolkit at the Load Balancer(s).

:information_source:&nbsp; This config is the same for custom Load Balancers. Although please note, in this setup it's expected that all required balancing rules are in place and the URL to connect to the Balancer(s) never change. For the latest balancer rules you need to configure you should refer to the HAProxy config files provided as part of the Toolkit - [External](../ansible/roles/haproxy/templates/haproxy_external.cfg.j2), [Internal](../ansible/roles/haproxy/templates/haproxy_internal.cfg.j2).

The available variables in Ansible for this are as follows:

- `external_url` - The external load balancer URL. This is expected to be the same as the main URL that the environment is to be accessed on.
- `internal_lb_host` - The hostname of the Internal Load Balancer (not URL). Provided in Terraform outputs if provisioned earlier.

## PostgreSQL

The Toolkit supports provisioning and/or configuring alternative PostgreSQL database(s) and then pointing GitLab to use them accordingly, much in the same way as configuring Omnibus Postgres.

When using alternative PostgreSQL database(s) the following changes apply when deploying via the Toolkit:

- Postgres and PgBouncer nodes don't need to be provisioned via Terraform.
- Praefect may use the same database instance unless Geo is being used. In such a case the Praefect Postgres node doesn't need to be provisioned.
- Consul doesn't need to be provisioned via Terraform unless you're deploying Prometheus via the Monitor node (needed for monitoring auto discovery).

### Database Setup Options

There are several databases GitLab can use depending on the setup as follows:

- GitLab - The main database for the application
- Praefect - The database for Praefect to track Gitaly node status
- Geo Tracking - The database for Geo to track sync status on a secondary site

How and where these are configured can be done in several ways depending on if Geo is being used:

- Non Geo
  - GitLab and Praefect can be configured on the same Database instance (recommended) or separated
- Geo 
  - GitLab and Praefect should be separated to avoid replication of the latter.
  - Geo Tracking DB can be configured on the same Database instance as Praefect on the secondary site (recommended) or separated

This section starts with the non Geo combined databases route with guidance being given on the alternatives where appropriate.

Head to the relevant section(s) below for details on how to provision and/or configure.

### Provisioning with Terraform

Provisioning a PostgreSQL database via a cloud service differs slightly per provider but has been designed in the Toolkit to be as similar as possible to deploying PostgreSQL via Omnibus. As such, it only requires some different config in your Environment's config file (`environment.tf`).

Like the main provisioning docs there are sections for each supported provider on how to achieve this. Follow the section for your selected provider and then move onto the next step.

#### AWS RDS

The Toolkit supports provisioning an AWS RDS PostgreSQL service instance with everything GitLab requires or recommends such as built in HA support over AZs and encryption.

The variables for this service start with the prefix `rds_postgres_*` and should replace any previous `postgres_*`, `pgbouncer_*` and `praefect_postgres_*` settings. The available variables are as follows:

- `rds_postgres_instance_type`- The [AWS Instance Type](https://aws.amazon.com/rds/instance-types/) for the RDS service to use without the `db.` prefix. For example, to use a `db.m5.2xlarge` RDS instance type, the value of this variable should be `m5.2xlarge`. **Required**.
- `rds_postgres_password` - The password for the instance. **Required**.
- `rds_postgres_username` - The username for the instance. Optional, default is `gitlab`.
- `rds_postgres_database_name` - The name of the main database in the instance for use by GitLab. Optional, default is `gitlabhq_production`.
- `rds_postgres_port` - The password for the instance. Should only be changed if desired. Optional, default is `5432`.
- `rds_postgres_version` - The version of the PostgreSQL instance. Should only be changed to versions that are supported by GitLab. Optional, default is `12.6`.
- `rds_postgres_allocated_storage` - The initial disk size for the instance. Optional, default is `100`.
- `rds_postgres_max_allocated_storage` - The max disk size for the instance. Optional, default is `1000`.
- `rds_postgres_multi_az` - Specifies if the RDS instance is multi-AZ. Should only be disabled when HA isn't required. Optional, default is `true`.
- `rds_postgres_default_subnet_count` - Specifies the number of default subnets to use when running on the default network. Optional, default is `2`.
- `rds_postgres_iops` - The amount of provisioned IOPS. Setting this implies a storage_type of "io1". Optional, default is `1000`.
- `rds_postgres_storage_type` - The type of storage to use. Optional, default is `io1`.
- `rds_postgres_kms_key_arn` - The ARN for an existing [AWS KMS Key](https://aws.amazon.com/kms/) to be used to encrypt the database instance. If not provided a new one the default AWS KMS key will be used. Optional, default is `null`.
  - **Warning** Changing this value after the initial creation will result in the database being recreated and will lead to **data loss**.
- [`rds_postgres_backup_retention_period`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance#backup_retention_period) - The number of days to retain backups for. Must be between 0 and 35. Must be greater than 0 for Geo primary instances. Optional, default is `null`.
- [`rds_postgres_backup_window`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance#backup_window) - The daily time range where backups will be taken, e.g. `09:46-10:16`. Optional, default is `null`.

To set up a standard AWS RDS PostgreSQL service for a 10k environment with the required variables should look like the following in your `environment.tf` file for a 10k environment is:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  [...]

  rds_postgres_instance_type = "m5.2xlarge"
  rds_postgres_password = "<postgres_password>"
}
```

:information_source:&nbsp; If a separate Database Instance for Praefect is desired then this can be done with the same settings above but with the `rds_praefect_postgres_*` prefix instead.

Once the variables are set in your file you can proceed to provision the service as normal. Note that this can take several minutes on AWS's side.

Once provisioned you'll see several new outputs at the end of the process. Key from this is the `rds_host` output, which contains the address for the database instance that then needs to be passed to Ansible to configure. Take a note of this address for the next step.

##### Geo

When setting up Geo with RDS you must specify some extra settings to enable replication from the primary RDS instance to the secondary.

###### Primary Site

`rds_postgres_backup_retention_period` must have a value (in days) greater than 0 to enable it as a replication source.

###### Secondary Site

- `rds_postgres_kms_key_arn` should be set to the same KMS key ARN that was used to encrypt the primary sites RDS instance, the key will be shown in the output of the primary sites Terraform run.
- `rds_postgres_replication_database_arn` must be set to the ARN for the primary sites RDS instance. The ARN will be shown in the output of the primary sites Terraform run.

When using RDS with Geo, the secondary site will require separate RDS instance(s) for Praefect Postgres and the Geo Tracking database. The Tracking database and Praefect database can share a single separate instance or can be separated out into their own instances.

To configure these you can copy all the same variables listed above and replace `rds_postgres_*` with `rds_praefect_postgres_*` or `rds_geo_tracking_postgres_*` respectively with the following considerations:

- If you want the 2 databases to share a single instance then you only need to specify `rds_praefect_postgres_*` settings, which will also be used for the Geo Tracking database.
- If you're not using Gitaly Cluster (and therefore Praefect) then you must provide `rds_geo_tracking_postgres_*` settings.
- Similar to the main Postgres instance the only properties required to create an instance are `*_instance_type` and `*_password`.

Please note that on the primary site it is possible to use a single RDS instance to house both the main GitLab database and the Praefect database. With this configuration you can avoid having 2 RDS instances for the primary site to reduce costs. The Praefect database will be replicated over to the secondary site and ignored.

### Configuring with Ansible

Configuring GitLab to use an alternative PostgreSQL database with Ansible is the same regardless of its origin. All that's required are a few tweaks to your [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`) to point the Toolkit at the PostgreSQL instance(s).

:information_source:&nbsp; This config is the same for custom PostgreSQL databases that have been provisioned outside of Omnibus or Cloud Services. Although please note, in this setup it's expected that HA is in place and the URL to connect to the PostgreSQL instance never changes.

As detailed in [Database Setup Options](#database-setup-options) GitLab has several potential databases to configure. This section will start with the combined non Geo route with additional guidance given for the alternatives.

The required variables in Ansible for this are as follows:

- `postgres_host` - The hostname of the PostgreSQL instance. Provided in Terraform outputs if provisioned earlier. **Required**.
- `postgres_password` - The password for the instance. **Required**.
- `postgres_username` - The username of the PostgreSQL instance. Optional, default is `gitlab`.
- `postgres_database_name` - The name of the main database in the instance for use by GitLab. Optional, default is `gitlabhq_production`.
- `postgres_port` - The port of the PostgreSQL instance. Should only be changed if the instance isn't running with the default port. Optional, default is `5432`.
- `postgres_load_balancing_hosts` - A list of all PostgreSQL hostnames to use in [Database Load Balancing](https://docs.gitlab.com/ee/administration/postgresql/database_load_balancing.html). This is only applicable when running with an alternative Postgres setup (non Omnibus) where you have multiple read replicas. The main host should also be included in this list to be used in load balancing. Optional, default is `[]`.
- `praefect_postgres_username` - The username to create for Praefect on the PostgreSQL instance. Optional, default is `praefect`.
- `praefect_postgres_password` - The password for the Praefect user on the PostgreSQL instance. **Required**.
- `praefect_postgres_database_name` - The name of the database to create for Praefect on the PostgreSQL instance. Optional, default is `praefect_production`.

Depending on your Database instance setup some additional config may be required:

- `postgres_migrations_host` / `postgres_migrations_port` - Required for running GitLab Migrations if the main connection is not direct (e.g. via a connection pooler like PgBouncer). This should be set to the direct connection details of your database.
- `postgres_admin_username` / `postgres_admin_password` - Required if the admin username for the Database instance differs from the main one.

If a separate Database instance is to be used for Praefect then the additional following config may be required:

- `praefect_postgres_host` / `praefect_postgres_port` - Host and port for the Praefect database.
- `praefect_postgres_cache_host` / `praefect_postgres_cache_port` - Host and port for the [Praefect cache connection](https://docs.gitlab.com/ee/administration/gitaly/praefect.html#reads-distribution-caching). This should be either set to the direct connection or through a PgBouncer connection that has session pooling enabled.
- `praefect_postgres_migrations_host` / `praefect_postgres_migrations_port` - Required for running Praefect Migrations if the main connection is not direct (e.g. via a connection pooler like PgBouncer). This should be set to the direct connection details of your database.
- `praefect_postgres_admin_username` / `praefect_postgres_admin_password` - Required if the admin username for the Database instance differs from the main one.

Once set, Ansible can then be run as normal. During the run it will configure the various GitLab components to use the database as well as any additional tasks such as setting up a separate database in the same instance for Praefect.

After Ansible is finished running your environment will now be ready.

#### Geo

When setting up Geo with RDS you must specify some extra settings to configure the RDS instances being used. To configure these you can copy all the same variables listed above and replace `postgres_*` with `praefect_postgres_*` or `geo_tracking_postgres_*` respectively with the below considerations.

##### Primary Inventory

- `praefect_postgres_host` - Only required if you are using a separate Praefect RDS instance. If this is not set then the `postgres_*` settings will be used and the Praefect database will be co-located in the GitLab RDS instance.

##### Secondary Inventory

- `praefect_postgres_host` - This must be set to a separate RDS instance than the main GitLab instance for the secondary site, this is due to the main instance being a read-only replica.
- `geo_tracking_postgres_host` - By default this will use the same database used for Praefect. If Gitaly cluster is not being used then this must be set to a separate RDS instance than the main GitLab instance.
- `geo_tracking_postgres_port` - By default the Geo tracking database uses port `5431`, if the Geo tracking database is sharing an RDS instance with Praefect this needs to be set to the same value as `praefect_postgres_port` (`5432` by default).

##### All Inventory

- `postgres_host` - Should point to the primary sites GitLab RDS instance.
- `geo_secondary_postgres_host` - Should point to the secondary sites GitLab RDS instance.
- `geo_secondary_praefect_postgres_host` - If using Gitaly cluster this should point to the separate RDS instance being used for Praefect.
- `geo_tracking_postgres_host` - Should only be set if using a separate RDS instance for the Geo tracking database, if this is being co-located with Praefect this should not be set.

## Redis

The Toolkit supports provisioning and/or configuring an alternative Redis store and then pointing GitLab to use it accordingly, much in the same way as configuring Omnibus Redis.

When using an alternative Redis store the following changes apply when deploying via the Toolkit:

- The Toolkit can provision either a combined Redis store or separated ones for Cache and Persistent queues respectively, much like Omnibus Redis, depending on the size of Reference Architecture being followed.
- Redis, Redis Cache or Redis Persistent nodes don't need to be provisioned via Terraform.
- [GitLab specifically doesn't support Redis Cluster](https://docs.gitlab.com/ee/administration/redis/replication_and_failover_external.html#requirements). As such the Toolkit is always setting up Redis in a replica setup.

Head to the relevant section(s) below for details on how to provision and/or configure.

### Provisioning with Terraform

Provisioning an alternative Redis store via a cloud service differs slightly per provider but has been designed in the Toolkit to be as similar as possible to deploying Redis via Omnibus. As such, it only requires some different config in your Environment's config file (`environment.tf`).

Like the main provisioning docs there are sections for each supported provider on how to achieve this. Follow the section for your selected provider and then move onto the next step.

#### AWS Elasticache

The Toolkit supports provisioning an AWS Elasticache Redis service instance with everything GitLab requires or recommends such as built in HA support over AZs and encryption.

There's different variables to be set depending on the target architecture size and if it requires separated Redis instances (10k and up). First we'll detail the general settings that apply to all Redis setups:

The variables to set are dependent on if the setup is to have combined or separated Redis queues depending on the target Reference Architecture. The only difference is that the prefix of each variable changes depending on what Redis instances you're provisioning - `elasticache_redis_*`, `elasticache_redis_cache_*` and `elasticache_redis_persistent_*`, each replacing any existing `redis_*`, `redis_cache_*` or `redis_persistent_*` variables respectively.

For required variables they need to be set for each Redis service you are provisioning:

- `elasticache_redis_instance_type` - The [AWS Instance Type](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html) of the Redis instance to use without the `cache.` prefix. For example, to use a `cache.m5.2xlarge` Elasticache instance type, the value of this variable should be `m5.2xlarge`. **Required**.
  - `elasticache_redis_cache_instance_type` or `elasticache_redis_persistent_instance_type` when setting up separate services.
- `elasticache_redis_node_count` - The number of replicas of the Redis instance to have for failover purposes. This should be set to at least `2` or higher for HA and `1` if this isn't a requirement. **Required**.
  - `elasticache_redis_cache_node_count` or `elasticache_redis_persistent_node_count` when setting up separate services.
- `elasticache_redis_kms_key_arn` - The ARN for an existing [AWS KMS Key](https://aws.amazon.com/kms/) to be used to encrypt the Redis instance. If not provided the default AWS KMS key will be used instead. Optional, default is `null`.
  - `elasticache_redis_cache_kms_key_arn` or `elasticache_redis_persistent_kms_key_arn` when setting up separate services.
  - **Warning** Changing this value after the initial creation will result in the Redis instance being recreated and may lead to **data loss**.

For optional variables they work in a default like manner. When configuring for any Redis types the main `elasticache_redis_*` variable can be set once and this will apply to all but you can also additionally override this behavior with specific variables as follows:

- `elasticache_redis_password` - The password of the Redis instance. Must follow the [requirements as mandated by AWS](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/auth.html#auth-overview). **Required**.
  - Optionally `elasticache_redis_cache_password` or `elasticache_redis_persistent_password` can be used to override for separate services.
- `elasticache_redis_engine_version` - The version of the Redis instance. Should only be changed to versions that are supported by GitLab. Optional, default is `6.x`.
  - Optionally `elasticache_redis_cache_engine_version` or `elasticache_redis_persistent_engine_version` can be used to override for separate services.
- `elasticache_redis_port` - The port of the Redis instance. Should only be changed if required. Optional, default is `6379`.
  - Optionally `elasticache_redis_cache_port` or `elasticache_redis_persistent_port` can be used to override for separate services.
- `elasticache_redis_multi_az` - Specifies if the Redis instance is multi-AZ. Should only be disabled when HA isn't required. Optional, default is `true`.
  - Optionally `elasticache_redis_cache_multi_az` or `elasticache_redis_persistent_multi_az` can be used to override for separate services.
- [`elasticache_redis_snapshot_retention_limit`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group#snapshot_retention_limit) -  The number of days to retain backups for. Optional, default is `null`.
  - Optionally `elasticache_redis_cache_snapshot_retention_limit` or `elasticache_redis_persistent_snapshot_retention_limit` can be used to override for separate services.
- [`elasticache_redis_snapshot_window`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group#snapshot_window) - The daily time range where backups will be taken, e.g. `09:46-10:16`. Optional, default is `null`.
  - Optionally `elasticache_redis_cache_snapshot_window` or `elasticache_redis_persistent_snapshot_window` can be used to override for separate services.
- `elasticache_redis_default_subnet_count` - Specifies the number of default subnets to use when running on the default network. Optional, default is `2`.

If deploying a combined Redis setup that contains all queues (5k and lower) the following settings should be set (replacing any previous `redis_*` settings):

As an example, to set up a standard AWS Elasticache Redis service for a [5k](https://docs.gitlab.com/ee/administration/reference_architectures/5k_users.html) environment with the required variables should look like the following in your `environment.tf` file:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  [...]

  elasticache_redis_node_count = 2
  elasticache_redis_instance_type = "m5.large"
}
```

And for a larger environment, such as a [10k](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html), where Redis is separated:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  [...]

  elasticache_redis_cache_node_count = 2
  elasticache_redis_cache_instance_type = "m5.xlarge"

  elasticache_redis_persistent_node_count = 2
  elasticache_redis_persistent_instance_type = "m5.xlarge"
}
```

Once the variables are set in your file you can proceed to provision the service as normal. Note that this can take several minutes on AWS's side.

Once provisioned you'll see several new outputs at the end of the process. Key from this is the `elasticache_redis*_host` output, which contains the address for the Redis instance that then needs to be passed to Ansible to configure. Take a note of this address for the next step.

### Configuring with Ansible

Configuring GitLab to use alternative Redis store(s) with Ansible is the same regardless of its origin. All that's required is a few tweaks to your [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`) to point the Toolkit at the Redis instance(s).

:information_source:&nbsp; This config is the same for custom Redis instance(s) that have been provisioned outside of Omnibus or Cloud Services. Although please note, in this setup it's expected that HA is in place and the URL to connect to the Redis instance(s) never changes.

The variables to set are dependent on if the setup is to have combined or separated Redis queues depending on the target Reference Architecture. The only different is that the prefix of each variable changes depending on what Redis instances you're provisioning - `redis_*`, `redis_cache_*` and `redis_persistent_*` respectively. All of the variables are the same for each instance type and are described once below:

- `redis_host` - The hostname of the Redis instance. Provided in Terraform outputs if provisioned earlier. **Required**.
  - Becomes `redis_cache_host` or `redis_persistent_host` when setting up separate stores.
- `redis_port` - The port of the Redis instance. Should only be changed if required. Optional, default is `6379`.
  - Becomes `redis_cache_port` or `redis_persistent_port` when setting up separate stores. Will default to `redis_port` if not specified.
- `redis_external_ssl` - Sets GitLab to use SSL connections to the Redis store. Redis stores provisioned by the Toolkit will always use SSL. Should only be changed when using a custom Redis store that doesn't have SSL configured. Optional, default is `true`.

Once set, Ansible can then be run as normal. During the run it will configure the various GitLab components to use the database as well as any additional tasks such as setting up a separate database in the same instance for Praefect.

After Ansible is finished running your environment will now be ready.

### Sensitive variable handling

When configuring these alternatives you'll sometimes need to configure sensitive values such as passwords. Earlier in the docs guidance was given on how to handle these more securely in both Terraform and Ansible. Refer to the below sections for further information.

- [Sensitive variable handling in Terraform](environment_provision.md#sensitive-variable-handling-in-terraform)
- [Sensitive variable handling in Ansible](environment_configure.md#sensitive-variable-handling-in-ansible)
