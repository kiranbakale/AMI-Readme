# Advanced - Network Setup

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [**GitLab Environment Toolkit - Advanced - Network Setup**](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

By default, the Toolkit will configure network setup using the default cloud provider's network. However, it can also support other advanced setups on select cloud providers such as creating a new network or using an existing one.

On this page we'll detail all of the supported advanced setups you can do with the Toolkit. We recommend you only do these setups if you have a good working knowledge of both the Toolkit and what the specific setups involve.

:warning:&nbsp; **{- Changing network setup on an existing environment must be treated with the utmost caution-}**. **Doing so can be considered a significant change and may trigger the recreation of the entire environment leading to data loss**.

[[_TOC_]]

## Configure network setup (GCP)

The module for GCP can configure the [network stack](https://cloud.google.com/vpc/docs/vpc) (VPC, Subnets, etc...) for your environment in several different ways:

- **Default** - Sets up the infrastructure on the default network stack as provided by GCP. This is the default for the module.
- **Created** - Creates the required network stack for the infrastructure.
- **Existing** - Will use a provided network stack passed in by the user.

In this section you will find the config required to set up each depending on your requirements.

:warning:&nbsp; **{- Changing network setup on an existing environment must be treated with the utmost caution-}**. **Doing so can be considered a significant change in GCP and may trigger the recreation of the entire environment leading to data loss**.

### Default (GCP)

This is the default setup for the module and is the recommended setup for most standard (Omnibus) environments where GCP will handle the networking by default.

No additional configuration is needed to use this setup.

To lock down network access to particular CIDR blocks follow [Configuring Network CIDR Access](#configuring-network-cidr-access) guidance.

### Created (GCP)

When configured the module will create a network stack to run the environment in. The network stack created is as follows:

- 1 VPC
- 1 Subnet
- Firewall rules to allow for required network connections

The environment's machines will be created in the created subnet.

This setup is recommended for users who want a specific network stack for their GitLab environment.

To configure this setup the following config should be added to the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf):

- `create_network` - This variable should be set to `true` when you are wanting the module to create a new network stack.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  create_network = true

  [...]
```

In addition to the above the following _optional_ settings change how the network is configured:

- `subnet_cidr`- A [CIDR block](https://cloud.google.com/vpc/docs/vpc#manually_created_subnet_ip_ranges) that will be used for the created subnet. This shouldn't need to be changed in most scenarios unless you want to use a specific CIDR blocks. Default is `"10.86.0.0/16"`

### Existing (GCP)

In this setup you have an existing network stack that you want the environment to use.

This is an advanced setup and you must ensure the network stack is configured correctly. This guide doesn't detail the specifics on how to do this but generally a stack should include the same elements as listed in the **Created** for the environment to work properly. Please refer to the GCP docs for more info.

Note that when this is configured the module will configure some GCP Firewall rules in your VPC to enable network access for the environment.

With an existing stack configure the following config should be added to the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf):

- `vpc_name` - The name of your existing VPC.
- `subnet_name` - The name of your existing Subnet. The subnet should be located in the same existing VPC.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  prefix = var.prefix
  project = var.project

  vpc_name = "<vpc-name>"
  subnet_name = "<subnet-name>"

  [...]
}
```

## Configure network setup (AWS)

By default the toolkit sets up the infrastructure on the default network stack as provided by AWS. However, it can also support other advanced setups such as creating a new network or using an existing one.

The module for AWS can configure the [network stack](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html) (VPC, Subnets, etc...) for your environment in several different ways:

- **Default** - Sets up the infrastructure on the default network stack as provided by AWS. This is the default for the module.
- **Created** - Creates the required network stack for the infrastructure
- **Existing** - Will use a provided network stack passed in by the user

Additionally for the Created and Existing network types above you can configure the subnets used to be private or public.

In this section you will find the config required to set up each depending on your requirements.

:warning:&nbsp; **{- Changing network setup on an existing environment must be avoided-}**. **Doing so is considered a significant change in AWS and will essentially trigger the recreation of the entire environment leading to data loss**.

### Default (AWS)

This is the default setup for the module where AWS will handle the networking by default. No additional configuration is needed to use this setup.

To lock down network access to particular CIDR blocks follow [Configuring Network CIDR Access](#configuring-network-cidr-access) guidance.

### Created (AWS)

When configured the module will create a network stack to run the environment in. The network stack created is as follows:

- 1 VPC
- 2 Subnets
  - Subnets are created in the created VPC and are additionally spread across the available Availability Zones in the selected region.
  - The number of Subnets is configurable.
- 1 Internet Gateway
- 1 Route Table

The environment's machines will be spread across the created subnets and their Availability Zones evenly.

This setup is recommended for users who want a specific network stack for their GitLab environment. It's also recommended for Cloud Native Hybrid environments running on AWS.

To configure this setup the following config should be added to the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf):

- `create_network` - This variable should be set to `true` when you are wanting the module to create a new network stack.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  create_network = true

  [...]
```

In addition to the above the following _optional_ settings change how the network is configured:

- `vpc_cidr_block` - The [CIDR block](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4) that will be used for your VPC. This shouldn't need to be changed in most scenarios unless you want to use a specific CIDR block. Default is `172.31.0.0/16`.
- `subnet_pub_count` - The number of subnets to create in the VPC. This should only be changed if you want an increased subnet count for availability reasons. Refer to the below [Created Subnet Types (Public / Private)](#created-subnet-types-public--private) section for more info. Default is `2`.
- `subnet_pub_cidr_block`- A list of [CIDR blocks](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4) that will be used for each public subnet created. This should be changed if you want to use specific CIDR blocks. Default is `["172.31.0.0/20","172.31.16.0/20","172.31.32.0/20"]`
  - The module has up to 3 subnet CIDR blocks it will use. If you have set `subnet_pub_count` higher than 3 then this variable will need to be adjusted to match the number of subnets to be created. The CIDR blocks will need to fit in the main block defined for the VPC via `vpc_cidr_block`.
- `subnet_priv_count` - The number of private subnets to create in the VPC. This should be changed if you want more resources to be created with private subnets. Refer to the below [Created Subnet Types (Public / Private)](#created-subnet-types-public--private) section for more info. Default is `0`.
- `subnet_priv_cidr_block`- A list of [CIDR blocks](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4) that will be used for each private subnet created. This should be changed if you want to use specific CIDR blocks. Default is `["172.31.128.0/20", "172.31.144.0/20", "172.31.160.0/20"]`
  - The module has up to 3 subnet CIDR blocks it will use. If you have set `subnet_priv_count` higher than 3 then this variable will need to be adjusted to match the number of subnets to be created. The CIDR blocks will need to fit in the main block defined for the VPC via `vpc_cidr_block`.
- `zones_exclude` - In rare cases you may need to avoid specific Availability Zones [as they don't have the available resource to deploy the infrastructure in](https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-creation-errors/). When this is the case you can specify a list of Zones by name via this setting that will then be avoided by the Toolkit, e.g. `["us-east-1e"]`. Default is `null`.
- `availability_zones` - Availability Zones resources should be spread across. By default (subject to `zones_exclude`) zones are  automatically chosen in the VPC by lexical order (i.e. when two subnets are requested they will be in the zones with suffixes `a`, `b`). In some circumstances (e.g. exposing services via PrivateLink to other accounts) it may be desirable to choose the Availability Zones more precisely but still allow the Toolkit to create all the resources. In these cases, you can supply the list of Zones to use. If you supply fewer zones than the number of subnets, zones will be re-used in round-robin order; if you supply more zones than the number of subnets (N), only the first N zones will be used. `zones_exclude` will _not_ be applied to this list. Default is `[]`.

#### Created Subnet Types (Public / Private)

When creating a network the Toolkit supports creating both Public and Private subnets.

There are several possible combinations supported. The Toolkit will dynamically configure each based on what's been configured via the  `subnet_pub_count` and `subnet_priv_count` settings as follows:

- Public Subnets - The default. All resources are placed in public subnets and have public IPs.
  - When `subnet_pub_count` is higher than `0` and `subnet_priv_count` is `0`.
- Public + Private Subnets - All resources are placed in Private subnets by default except for those externally facing (HAProxy External, EKS Cluster + EKS Supporting Node that runs NGinx).
  - When `subnet_pub_count` is higher than `0` and `subnet_priv_count` is higher than `0`.
  - :information_source:&nbsp; **In this setup the number of Public and Private subnets must be the same**. This is to ensure [NAT Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) can be configured for each private subnet on the corresponding public subnet to allow Internet access.
- Private Subnets - A fully airgapped environment. All resources are placed in private subnets, additional setup will be required for GitLab to install such as private OS package repos, etc... along with resources such as private links to access.
  - When `subnet_pub_count` is `0` and `subnet_priv_count` is higher than `0`.

:information_source:&nbsp; When Private subnets are being used most VMs won't have a public IP address. As such, when running Ansible it should be run from within the network [with its Dynamic Inventory configured to connect via private IPs](environment_configure.md#amazon-web-services-aws) (`compose.ansible_host` set to `private_ip_address`).

### Existing (AWS)

In this setup you have an existing network stack that you want the environment to use.

This is an advanced setup and you must ensure the network stack is configured correctly. This guide doesn't detail the specifics on how to do this but generally a stack should include the same elements as listed in the **Created** for the environment to work properly. Please refer to the AWS docs for more info.

Note that when this is configured the module will configure some AWS Security Groups in your VPC to enable network access for the environment.

With an existing stack configure the following config should be added to the [module's environment config file](environment_provision.md#configure-module-settings-environmenttf):

- `vpc_id` - The ID of your existing VPC
- `subnet_pub_ids` - A list of public subnet IDs the environment's machines should be spread across. The subnets should be located in the same existing VPC. Refer to the below [Existing Subnet Types (Public / Private)](#existing-subnet-types-public--private) section for more info.
- `subnet_priv_ids` - A list of private subnet IDs the environment's machines should be spread across. The subnets should be located in the same existing VPC and have any desired dependent infrastructure, e.g. NAT Gateway for internet access. Refer to the below [Existing Subnet Types (Public / Private)](#existing-subnet-types-public--private) section for more info.

An example of your environment config file with public subnets would look like:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key = file(var.ssh_public_key_file)

  vpc_id = "<vpc-id>"
  subnet_pub_ids = ["<public-subnet-1-id>", "<public-subnet-2-id>"]

  [...]
```

#### Existing Subnet Types (Public / Private)

When providing an existing network to the Toolkit it also supports the passthrough of public / private subnets.

There are several possible combinations supported. The Toolkit will dynamically configure each based on what's been configured via the  `subnet_pub_ids` and `subnet_priv_ids` settings as follows:

- Public Subnets - The default. All resources are placed in public subnets and have public IPs.
  - When `subnet_pub_ids` is higher than `0` and `subnet_priv_ids` is `0`.
- Public + Private Subnets - All resources are placed in Private subnets by default except for those externally facing (HAProxy External, EKS Cluster + EKS Supporting Node that runs NGinx).
  - When `subnet_pub_ids` is higher than `0` and `subnet_priv_ids` is higher than `0`.
  - :information_source:&nbsp; In this setup resources running on Private Subnets require Internet access via a [NAT Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) to be configured.
- Private Subnets - A fully airgapped environment. All resources are placed in private subnets, additional setup will be required for GitLab to install such as private OS package repos, etc... along with resources such as private links to access.
  - When `subnet_pub_ids` is `0` and `subnet_priv_ids` is higher than `0`.

:information_source:&nbsp; When Private subnets are being used most VMs won't have a public IP address. As such, when running Ansible it should be run from within the network [with its Dynamic Inventory configured to connect via private IPs](environment_configure.md#amazon-web-services-aws) (`compose.ansible_host` set to `private_ip_address`).

## Configuring Network CIDR Access

The Toolkit has multiple CIDR block settings to allow configuring network access to the environment for both external and internal connections. Through these settings you can restrict network access as required.

By default the Toolkit will have these settings open to all connections. This is to allow you to get the environment up and running and then to configure the settings as desired, much like a standard build.

Refer to the below sections for more detail.

### External (Terraform)

To lock down external network access to particular CIDR blocks these _optional_ settings can be used in Terraform:

- `default_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access the network externally. This will apply to all external firewall rules that the Toolkit configures. Default is `["0.0.0.0/0"]`. More granular control over rules are also available via these settings:
  - `http_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access GitLab over HTTP/HTTPs.
  - `ssh_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access GitLab over SSH.
  - `external_ssh_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access the network over SSH.
  - `icmp_allowed_ingress_cidr_blocks`- **GCP and Azure only** - A list of CIDR blocks that configures the IP ranges that will be able to access the network over ICMP.

:warning:&nbsp; **{- Changing network setup on an existing environment must be treated with the utmost caution-}**. **Doing so can be considered a significant change in GCP and may trigger the recreation of the entire environment leading to data loss**.

### Internal (Ansible)

To lock down internal network access to particular CIDR blocks these _optional_ settings can be used in Ansible:

- `gitlab_rails_monitoring_cidr_blocks` - A list of CIDR blocks allowed to access [GitLab's Health Check endpoints](https://docs.gitlab.com/ee/user/admin_area/monitoring/health_check.html). Required for Load Balancers to perform Health Checks. Note that if changing this setting it should include any Load Balancers performing health checks, including any Toolkit provided HAProxy Load Balancers. Default is `['0.0.0.0/0']`.
- `postgres_trust_auth_cidr_blocks` - A list of CIDR blocks allowed to access [Postgres (Omnibus)](https://docs.gitlab.com/omnibus/settings/database.html#configure-postgresql-block). Default is `['0.0.0.0/0']`.
- `postgres_md5_auth_cidr_blocks` - A list of CIDR blocks allowed to access [Postgres (Omnibus)](https://docs.gitlab.com/omnibus/settings/database.html#configure-postgresql-block) with authentication. Default is `['0.0.0.0/0']`.
  - :information_source:&nbsp; Changes to this setting currently has some known issues in certain setups - [gitlab-org/omnibus-gitlab#6594](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6594) and [gitlab-org/omnibus-gitlab#6590](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6590).
  - :information_source:&nbsp; [There are additional considerations for this setting when using Geo](https://docs.gitlab.com/ee/administration/geo/setup/database.html#postgresql-replication).
- `geo_tracking_postgres_md5_auth_cidr_blocks` - A list of CIDR blocks allowed to access [Geo Tracking Postgres (Omnibus)](https://docs.gitlab.com/ee/administration/geo/replication/multiple_servers.html#step-3-configure-the-geo-tracking-database-on-the-geo-secondary-site). Default is `['0.0.0.0/0']`.

## Configuring Internal Connection Type (IPs / Hostnames)

The Toolkit by default uses IPs for internal connections. However this can be switched to use internal hostnames as discovered by Ansible via the following setting in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `internal_addr_use_hostnames` - Flag to switch the Toolkit to use internal hostnames for connections. Default is `false`.

:information_source:&nbsp; On the main Cloud Providers internal hostnames are available by default (For more info - [GCP](https://cloud.google.com/compute/docs/internal-dns), [AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-naming.html), [Azure](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-name-resolution-for-vms-and-role-instances#reverse-dns-considerations)). Terraform output shows the hostnames for each VM. For On Prem installs hostnames and DNS will need to be configured separately.
