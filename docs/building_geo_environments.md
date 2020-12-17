# Building an environment with Geo

---
**NOTE**

The GitLab Environment Toolkit is in **Alpha** (`v1.0.0-alpha`) and work is currently under way for its main release.

As such, **this documentation is currently out of date** but we aim to have this updated soon.

For more information about this release please refer to this [Epic](https://gitlab.com/groups/gitlab-org/-/epics/5061).

---

- [GitLab Environment Toolkit - Preparing the toolkit](prep_toolkit.md)
- [GitLab Environment Toolkit - Building environments](building_environments.md)
- [**GitLab Environment Toolkit - Building an environment with Geo**](building_geo_environments.md)

[[_TOC_]]

When provisioning a Geo deployment there are a few differences to a single environment that need to be made throughout the process to allow the GitLab Environment Toolkit to properly manage the deployment:

- Both environments should share the same admin credentials. For example in the case of GCP the same Service Account.
- The GitLab license is shared between the 2 sites. This means the license only needs to be applied to the primary site.

As shown above, for the most part, the process is the same as when creating a single environment and as such the [GitLab Environment Toolkit - Preparing the toolkit](prep_toolkit.md) steps will need to be followed before creating a Geo deployment.

The process used to build the environments follows the documentation for [Geo for multiple nodes](https://docs.gitlab.com/ee/administration/geo/replication/multiple_servers.html). The high level steps that will be followed are:

1. Provision 2 environments with Terraform
    - Each environment will share some common labels to identify them as being part of the same Geo deployment
    - One environment will be identified as being a Primary site and one will be a Secondary
1. Configure the environments with Ansible
    - Each environment will work as a separate environment until Geo is configured
1. Configure Geo on the Primary and Secondary sites

## Terraform

When creating a new Terraform site for Geo it is recommended to create a new subfolder for your Geo deployment with 2 sub-folders below that for the primary and secondary config. Although not required this does help to keep all the config for a single Geo deployment in one location. The 2 separate environments however will always still need their own folders here for Terraform to manage their State correctly.

```bash
my-geo-deployment
    ├── primary
    └── secondary
```

After this it is recommended to copy an existing reference architecture for the primary and secondary folders. You could copy the 25k reference architecture to use as your primary site and the 3k for your secondary, or use 5k for both your primary and secondary sites, the Geo process will work for any combination with the same steps.

The main steps for [GitLab Environment Toolkit - Building environments](building_environments.md) should be followed when creating a new Terraform project.

Once you have copied the desired architecture sizes we will need to modify all the `.tf` files to allow for Geo. The first step is to add 2 new labels to each of our machines to help identify them as belonging to our Geo deployment and if it is part of the primary or secondary site.

> You do not need to add the label fields to the `firewall.tf`, `main.tf`, `storage.tf` or `variables.tf` files. These files do not create new machines and as such do not require labels.

In each of the `.tf` files that need altering there will be at least one code block identified as a module, some files may contain more than one and the labels should be added to both. In here we add 2 new lines at the end of the module. Each module will also contain a `source` property, the path used here will be incorrect if you've followed the folder structure above. You will need to add an additional `../` to the path as we are now using sub-folders. The example below shows the correct path.
These changes will need to be made in both the `primary` and `secondary` folders:
<details>
  <summary>Example `consul.tf`</summary>

```terraform
  module "consul" {
    source = "../../modules/gitlab_gcp_instance"

    prefix = "${var.prefix}"
    node_type = "consul"
    node_count = 3

    geo_site = "${var.geo_site}"
    geo_deployment = "${var.geo_deployment}"

    machine_type = "n1-highcpu-2"
    machine_image = "${var.machine_image}"
  }

  output "consul" {
    value = module.consul
  }
```

</details>

Next we need to modify the `variables.tf` files to set the 2 new variables.

- `geo_site` is used to identify if a machine belongs to the primary or secondary site.
- `geo_deployment` is used to identify that a primary and secondary site belong to the same Geo deployment.

It should also be noted that the existing `prefix` variable should still be unique to each Terraform project and shouldn't be shared across a Geo deployment.
If copying the `variables.tf` from another environment you will need to update the `credentials` parameter to now account for the extra subfolder.

<details>
  <summary>Example Primary `variables.tf`</summary>

  ```terraform
    variable "project" {
      default = "<Project ID>"
    }

    variable "credentials_file" {
      default = "<Credentials>"
    }

    variable "region" {
      default = "us-east1"
    }

    variable "zone" {
      default = "us-east1-c"
    }

    variable "prefix" {
      default = "my-10k-environment"
    }

    variable "machine_image" {
      default = "ubuntu-1804-lts"
    }

    variable "external_ip" {
      default = "<external ip>"
    }

    variable "geo_site" {
      default = "geo-primary"
    }

    variable "geo_deployment" {
      default = "my-geo-deployment"
    }
  ```

</details>

When updating the secondaries `variables.tf` you can change the `region` and `zone` properties to use different values than the primaries. Although not required this helps to better represent a typical Geo setup.

<details>
  <summary>Example Secondary `variables.tf`</summary>

  ```terraform
    variable "project" {
      default = "<Project ID>"
    }

    variable "credentials_file" {
      default = "<Credentials>"
    }

    variable "region" {
      default = "europe-west4"
    }

    variable "zone" {
      default = "europe-west4-a"
    }

    variable "prefix" {
      default = "my-3k-environment"
    }

    variable "machine_image" {
      default = "ubuntu-1804-lts"
    }

    variable "external_ip" {
      default = "<external ip>"
    }

    variable "geo_site" {
      default = "geo-secondary"
    }

    variable "geo_deployment" {
      default = "my-geo-deployment"
    }
  ```

</details>

Finally we will need to update the `main.tf` file, the only change required for Geo is only required if using the subfolder file structure. The `credentials` path will need to be updated to account for the sub-folders.

> Alpha support for [multi-node PostgreSQL](https://gitlab.com/groups/gitlab-org/-/epics/2536) with Patroni is currently in development. When using repmgr on the secondary site the `node_count` in `postgres.tf` should be set to 1 for the secondary sites config. When using Patroni, this can be left at its original value.

Once each site is configured we can run the `terraform apply` command against each project. You can run this command against the primary and secondary sites at the same time.

## Ansible

We will need to start by creating new inventories for a Geo deployment. For Geo we will require 3 inventories: `primary`, `secondary` and `all`. It is recommended to store these in one parent folder to keep all the config together.

```bash
my-geo-deployment
    ├── all
    ├── primary
    └── secondary
```

The `primary` and `secondary` folders are treated the same as non Geo environments and as such the steps for [GitLab Environment Toolkit - Building environments](building_environments.md#2-configuring-gitlab-on-the-environment-with-ansible) should be followed, you should remove the GitLab license from the secondary site before running the `ansible-playbook` command. To remove the license from the secondary site you can just remove the `gitlab_license_file` setting from the secondary `vars.yml` file.

Once the inventories for primary and secondary are complete you can use Ansible to configure GitLab. Once complete you will have 2 independent instances of GitLab. The primary site should have a license installed and the secondary will not.
As these environments are still separate from each other at this point, they can be built at the same time and are not reliant on each other. Once complete you should be able to log into each environment before continuing.

The `all` inventory is very similar to the `primary` and `secondary`, it allows Ansible to see both sites instead of one for the tasks that require coordination across both environments. To create the `all` inventory files it is easiest to copy them from `primary` and modify some values as follows:

### `vars.yml`

Add the line `secondary_external_url` which needs to match the `external_url` in the `secondary` inventory vars file. You can also remove the properties: `cloud_provider`, `prefix`, `gitlab_license_file`, `install_patroni` and `gitlab_root_password_file`. These are not used when configuring Geo and as such should only be set in the `primary` and `secondary` inventories.

### `all.gcp.yml`

Under the `keyed_groups` section add 2 new keys that allow Ansible to identify machines based on the Geo deployment and a machines role within that deployment:

```yaml
- key: labels.gitlab_geo_site
  separator: ''
- key: labels.gitlab_geo_full_role
  separator: ''
```

`gitlab_geo_full_role` is a label that is created for us by a Terraform module, this label is a combination of `geo_site`, `node_type` and `node_level`. Using this we can get the IP of a machine directly by its role in a Geo deployment from a single label.

Under the `filters` section we want to remove the existing filter and replace it with:

```yaml
filters:
  - labels.gitlab_geo_deployment = my-geo-deployment
```

The existing filter is based on an environments prefix, this is unique to each environment. The Geo deployment is how we identify multiple environments to run our Geo configuration against.

Once done we can then run the command
`ansible-playbook -i inventories/my-geo-deployment/all gitlab-geo.yml`

Once complete the 2 sites will now be part of the same Geo deployment.
