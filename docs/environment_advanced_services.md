# Advanced - Cloud Services

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [**GitLab Environment Toolkit - Advanced - Cloud Services**](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo, Advanced Search, Custom Config and more](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)

The Toolkit supports using Cloud Services for select components instead of deploying them directly via Omnibus or the Helm charts - namely PostgreSQL and Redis. The Toolkit includes both provisioning and configuration of these services seamlessly within AWS.

On this page we'll detail how to setup the Toolkit to provision and configure these services. **It's worth noting this guide is supplementary to the rest of the docs and it will assume this throughout.**

[[_TOC_]]

## Overview

It can be more convenient to use a Cloud Service for select components rather than having to manage them more directly. These services have built in HA and don't require instance level maintenance.

Two components of the GitLab setup can be switched to a Cloud Service:

- [PostgreSQL](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#provide-your-own-postgresql-instance) - [AWS RDS](https://aws.amazon.com/rds/postgresql/), [Google Cloud SQL](https://cloud.google.com/sql/docs/postgres)
- [Redis](https://docs.gitlab.com/ee/administration/reference_architectures/10k_users.html#providing-your-own-redis-instance) - [AWS Elasticache](https://aws.amazon.com/elasticache/redis/), [Google Memorystore](https://cloud.google.com/memorystore/docs/redis)

## PostgreSQL

The Toolkit supports provisioning and configuring a PostgreSQL Cloud Service and then pointing GitLab to use it accordingly, much in the same way as configuring Omnibus Postgres.

When using a PostgreSQL Cloud Service the following changes apply when deploying via the Toolkit:

- Postgres and PgBouncer nodes don't need to be provisioned via Terraform.
- Praefect will use the same database instance. As such the Praefect Postgres node also doesn't need to be provisioned.
- Consul doesn't need to be provisioned via Terraform unless you're deploying Prometheus via the Monitor node (needed for monitoring auto discovery).

Refer to the specific cloud service section below on how to configure.

### Provisioning with Terraform

Provisioning the PostgreSQL Cloud Service differs slightly per provider but has been designed in the Toolkit to be as similar as possible to deploying PostgreSQL via Omnibus. As such, it only requires some different config in your Environment's config file (`environment.tf`).

Like the main provisioning docs there are sections for each supported provider on how to achieve this. Follow the section for your selected provider and then move onto the next step.

#### AWS RDS

The Toolkit supports provisioning an AWS RDS PostgreSQL service instance with everything GitLab requires such as built in HA support.

The variables for this service start with the prefix `rds_postgres_*` and should replace any previous `postgres_*`, `pgbouncer_*` and `praefect_postgres_*` settings. The available variables are as follows:

- `rds_postgres_instance_type`- The [AWS Instance Type](https://aws.amazon.com/ec2/instance-types/) for the RDS service to use wihtout the `db.` prefix. For example, to use a `db.m5.2xlarge` RDS instance type, the value of this variable should be `m5.2xlarge`. **Required**.
- `rds_postgres_password` - The password for the instance. **Required**.
- `rds_postgres_username` - The username for the instance. Optional, default is `gitlab`.
- `rds_postgres_database_name` - The name of the main database in the instance for use by GitLab. Optional, default is `gitlabhq_production`.
- `rds_postgres_port` - The password for the instance. Should only be changed if desired. Optional, default is `5432`.
- `rds_postgres_version` - The version of the PostgreSQL instance. Should only be changed to versions that are supported by GitLab. Optional, default is `12.6`.
- `rds_postgres_allocated_storage` - The initial disk size for the instance. Optional, default is `100`.
- `rds_postgres_max_allocated_storage` - The max disk size for the instance. Optional, default is `1000`.
- `rds_postgres_multi_az` - Specifies if the RDS instance is multi-AZ. Should only be disabled when HA isn't required. Optional, default is `true`
- `rds_postgres_iops` - The amount of provisioned IOPS. Setting this implies a storage_type of "io1". Optional, default is `1000`.
- `rds_postgres_storage_type` - The type of storage to use. Optional, default is `io1`.
- `rds_postgres_kms_key_arn` - The ARN for an existing [AWS KMS Key](https://aws.amazon.com/kms/) to be used to encrypt the database instance. If not provided a new one will be generated by Terraform for the RDS instance. Optional, default is `null`.
  - **Warning** Changing this value after the initial creation will result in the database being recreated and will lead to **data loss**.

To set up a standard AWS RDS PostgreSQL for a 10k environment with the required variables should look like the following in your `environment.tf` file for a 10k environment is:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  [...]

  rds_postgres_instance_type = "m5.2xlarge"
  rds_postgres_password = "<postgres_password>"
}
```

Once the variables are set in your file you can proceed to provision the service as normal. Note that this can take several minutes on AWS's side.

Once provisioned you'll see several new outputs at the end of the process. Key from this is the `rds_address` output, which contains the address for the database instance that then needs to be passed to Ansible to configure. Take a note of this address for the next step.

### Configuring with Ansible

Configuring GitLab to use a non Omnibus PostgreSQL instance with Ansible is the same regardless of which cloud provider you choose. All that's required is a few tweaks to your [Environment config file](environment_configure.md#environment-config-varsyml) (`vars.yml`) to point the Toolkit at the PostgreSQL instance.

It's worth noting this config will also work for a custom PostgreSQL instance that has been provisioned outside of Omnibus or Cloud Services. Although please note, in this setup it's expected that HA is in place and the URL to connect to the PostgreSQL instance never changes.

The available variables in Ansible for this are as follows:

- `postgres_host` - The hostname of the PostgreSQL instance. Provided in Terraform outputs if provisioned earlier. **Required**.
- `postgres_password` - The password for the instance. **Required**.
- `postgres_username` - The username of the PostgreSQL instance. Optional, default is `gitlab`.
- `postgres_database_name` - The name of the main database in the instance for use by GitLab. Optional, default is `gitlabhq_production`.
- `postgres_port` - The port of the PostgreSQL instance. Should only be changed if the instance isn't running with the default port. Optional, default is `5432`.

Along with the above there are some additional settings specific to Praefect and how its database will be set up on the PostgreSQL instance:

- `postgres_password` - The password for the Praefect user on the PostgreSQL instance. **Required**.
- `praefect_postgres_username` - The username to create for Praefect on the PostgreSQL instance. Optional, default is `praefect`.
- `praefect_postgres_database_name` - The name of the database to create for Praefect on the PostgreSQL instance. Optional, default is `praefect_production`.

Once set, Ansible can then be run as normal. During the run it will configure the various GitLab components to use the database as well as any additional tasks such as setting up a separate database in the same instance for Praefect.

After Ansible is finished running your environment will now be ready.
