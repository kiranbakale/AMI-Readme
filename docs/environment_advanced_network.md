# Advanced - Network Setup

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - External SSL](environment_advanced_ssl.md)
- [**GitLab Environment Toolkit - Advanced - Network Setup**](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Custom Config, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)

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

To lock down network access to particular CIDR blocks follow [Restricting External Network Access](#restricting-external-network-access) guidance.

### Created (GCP)

When configured the module will create a network stack to run the environment in. The network stack created is as follows:

- 1 VPC
- 1 Subnet
- Firewall rules to allow for required network connections

The environment's machines will be created in the created subnet.

This setup is recommended for users who want a specific network stack for their GitLab environment.

To configure this setup the following config should be added to the [module's environment config file](#configure-module-settings-environmenttf):

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

With an existing stack configure the following config should be added to the [module's environment config file](#configure-module-settings-environmenttf):

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

By default the toolkit sets up the infrastructure on the default network stack as provided by AWS. However, it can also support other advanced setups such as creating a new network or using an existing one. To learn more refer to [Configure network setup (GCP)](environment_advanced_network.md#configure-network-setup-aws).

The module for AWS can configure the [network stack](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html) (VPC, Subnets, etc...) for your environment in several different ways:

- **Default** - Sets up the infrastructure on the default network stack as provided by AWS. This is the default for the module.
- **Created** - Creates the required network stack for the infrastructure
- **Existing** - Will use a provided network stack passed in by the user

In this section you will find the config required to set up each depending on your requirements.

:warning:&nbsp; **{- Changing network setup on an existing environment must be avoided-}**. **Doing so is considered a significant change in AWS and will essentially trigger the recreation of the entire environment leading to data loss**.

### Default (AWS)

This is the default setup for the module where AWS will handle the networking by default. No additional configuration is needed to use this setup.

To lock down network access to particular CIDR blocks follow [Restricting External Network Access](#restricting-external-network-access) guidance.

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

To configure this setup the following config should be added to the [module's environment config file](#configure-module-settings-environmenttf-1):

- `create_network` - This variable should be set to `true` when you are wanting the module to create a new network stack.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key_file = file(var.ssh_public_key_file)

  create_network = true

  [...]
```

In addition to the above the following _optional_ settings change how the network is configured:

- `subnet_pub_count` - The number of subnets to create in the VPC. This should only be changed if you want increased subnet count for availability reasons. Default is `2`.
- `vpc_cidr_block` - The [CIDR block](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4) that will be used for your VPC. This shouldn't need to be changed in most scenarios unless you want to use a specific CIDR block. Default is `172.31.0.0/16`.
- `subpub_pub_cidr_block`- A list of [CIDR blocks](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4) that will be used for each subnet created. This shouldn't need to be changed in most scenarios unless you want to use a specific CIDR blocks. Default is `["172.31.0.0/20","172.31.16.0/20","172.31.32.0/20"]`
  - As a convenience the module has up to 3 subnet CIDR blocks it will use. If you have set `subnet_pub_count` higher than 3 then this variable will need to be adjusted to match the number of Subnets to be created.
- `zones_exclude` - In rare cases you may need to avoid specific Availability Zones [as they don't have the available resource to deploy the infrastructure in](https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-creation-errors/). When this is the case you can specify a list of Zones by name via this setting that will then be avoided by the Toolkit, e.g. `["us-east-1e"]`. Default is `null`.

### Existing (AWS)

In this setup you have an existing network stack that you want the environment to use.

This is an advanced setup and you must ensure the network stack is configured correctly. This guide doesn't detail the specifics on how to do this but generally a stack should include the same elements as listed in the **Created** for the environment to work properly. Please refer to the AWS docs for more info.

Note that when this is configured the module will configure some AWS Security Groups in your VPC to enable network access for the environment.

With an existing stack configure the following config should be added to the [module's environment config file](#configure-module-settings-environmenttf-1):

- `vpc_id` - The ID of your existing VPC
- `subnet_ids` - A list of Subnet IDs the environment's machines should be spread across. The subnets should be located in the same existing VPC.

An example of your environment config file then would look like:

```tf
module "gitlab_ref_arch_aws" {
  source = "../../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_public_key_file = file(var.ssh_public_key_file)

  vpc_id = "<vpc-id>"
  subnet_ids = ["<subnet-1-id>", "<subnet-2-id>"]

  [...]
```

## Restricting External Network Access

To lock down external network access to particular CIDR blocks these _optional_ settings can be used:

- `default_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access the network externally. This will apply to all external firewall rules that the Toolkit configures. Default is `["0.0.0.0/0"]`. More granular control over rules are also available via these settings:
  - `http_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access GitLab over HTTP/HTTPs.
  - `ssh_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access GitLab over SSH.
  - `monitor_allowed_ingress_cidr_blocks`- A list of CIDR blocks that configures the IP ranges that will be able to access the network for monitoring.
  - `icmp_allowed_ingress_cidr_blocks`- **GCP and Azure only** - A list of CIDR blocks that configures the IP ranges that will be able to access the network over ICMP.
  - `external_ssh_allowed_ingress_cidr_blocks`- **AWS and Azure only** - A list of CIDR blocks that configures the IP ranges that will be able to access the network over SSH.

:warning:&nbsp; **{- Changing network setup on an existing environment must be treated with the utmost caution-}**. **Doing so can be considered a significant change in GCP and may trigger the recreation of the entire environment leading to data loss**.
