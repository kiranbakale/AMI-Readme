# GitLab Environment Toolkit - Technical Design

This document serves as the Technical Design and Vision for the [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit). It aims to be a single source of truth covering areas such as design principles, technical implementations, reasonings and more.

Unless specified otherwise all additions, changes, etc... to the Toolkit should resonate with this document.

[[_TOC_]]

## What is the GitLab Environment Toolkit?

The GitLab Environment Toolkit (GET) is a collection of tools to deploy and operate production GitLab instances based on our [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/), including automation of common day 2 tasks, using the official [Omnibus](https://docs.gitlab.com/omnibus/) or [Helm](https://docs.gitlab.com/charts/) packages.

Created and maintained by the GitLab Quality Engineering Enablement team, the Toolkit - built with Terraform and Ansible - supports provisioning and configuring machines and other related infrastructure respectively.

### What is it not?

The Toolkit is **expressly** not a replacement for [Omnibus](https://docs.gitlab.com/omnibus/) or [Helm](https://docs.gitlab.com/charts/). It's a coordinator of these packages to help deploy GitLab at scale only with select supporting actions.

Outside of supporting the deployment of GitLab at scale (e.g. Load Balancers) the Toolkit shouldn't be automating actions that a user can't do themselves. It also shouldn't be handling tasks that are better suited to be done by Omnibus or Helm.

All feature requests and issues should be considered against this principle. Quite often requests are better raised against GitLab itself.

## Design Principles

### Simplicity

The main design principle for the Toolkit is the most important and informs its design completely - **Simplicity**. Echoing the GitLab value of [Boring solutions](https://about.gitlab.com/handbook/values/#boring-solutions) it's critical that simplicity is considered in all aspects of the Toolkit.

Provisioning and Configuration tools get complicated fast. There are typically many ways a certain action can be automated, many valid, but whatever we pick needs to be simple for both the user and the maintainer as detailed below.

#### User Experience

We strive to keep the user experience as simple as possible. Building full GitLab environments across numerous supported cloud providers results in there being _many_ levers available.

To make the Toolkit useful this needs to be streamlined down into a simple and usable interface that provides options to the user in an initiative way.

This is beholden in part to the tools we're using and their own interfaces but for each we still follow this principle of simplicity where possible.

#### Maintainer Experience

It's critical that all code we add to the Toolkit is simple where possible. Every addition needs to be maintained and simpler code is easier to read and understand. This is required even more so in a Toolkit like this as there's a wide range of code to review - Terraform, Ansible and Ruby (GitLab) - all with their own quirks and considerations.

We askew complicated code designs or patterns wherever possible to achieve this principle.

### Reference Architecture based design

The Toolkit is designed to deploy the supported [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures/). Other architectures are not supported at this time. This is achieve maintainability as well as test what we as a company actually recommend.

We also aim to provide supported customization and config hooks that are simple and maintainable.

### AHA - Avoid Hasty Abstractions

Generally we follow the pragmatic principle of [AHA - _Avoid Hasty Abstractions_](https://kentcdodds.com/blog/aha-programming#aha-) over [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself).

This works well for this type of tooling as by its nature - automation of tasks that are generally designed to be done manually - there may be times where repetition of tasks is required or maybe even desirable over complicated abstractions to achieve the required goal. Readability and Maintainability are more important as the code base we have is both wide and deep.

Some examples: 

- Select GitLab config is the same in GitLab Rails and Sidekiq. Extracting these would require abstracting outside of their Roles (breaking the point of Roles) and would become pretty hard to follow and maintain if it continued. It's easier to have a single source of truth for each component for readability and maintenance even if that means select config is the same in each.
- Some generated config files from GitLab need to be shared across component nodes but don't exist until the first node has completed setup. This requires code to be present in each Role to either copy the new file to a shared location or copy an existing one over at the right time to keep everything in sync. 

### Use Industry Leading Tools and Avoid Custom Implementations

We use industry leading tools natively for Provisioning and Configuration wherever possible - [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/). These tools are large, complex and mature it wouldn't be viable to try and replace or augment these.

We avoid custom code/implementations wherever possible as this will add additional maintenance cost.

## Technical Implementations

### Terraform

Our Terraform code follows a simple encapsulation approach through [Terraform Modules](https://www.terraform.io/docs/language/modules/develop/index.html).

There are modules created for each Cloud Provider (due to the numerous differences between them). Infrastructure code that can repeat often is a candidate to be moved into its own module.

The Toolkit uses two modules per cloud provider:

- `instance` - Contains all of the code required to deploy a VM suitable for GitLab on the selected Cloud Provider. 
- `ref_arch` - An encompassing module - it deploys VMs via the `instance` module along with any other supporting infrastructure such as Kubernetes, networking, object storage, etc... Variables are passed through to other modules/resources.
  - This module is designed to be flexible allowing users to only build what they want. Supporting resources should only be built if their dependent is.

In the future we might consider breaking select code down into more modules for further modularity. Overall the design though is to interface mainly through the relevant `ref_arch` module to give a consistent user experience.

#### Version Support

We support Terraform versions from `1.*` onwards. From time to time we may bump up this minimum supported version as required with adequate notice to users.

#### Styling

- Terraform code should follow the [Terraform Style Conventions](https://www.terraform.io/docs/language/syntax/style.html). All code should pass a `terraform fmt` check (automatically checked in CI).
- Terraform code should pass the project's lint checks. We utilize [`tflint`](https://github.com/terraform-linters/tflint) and a customized [rules list](.tflint.hcl).
- Variables should be set in the relevant `variables.tf` file for the module.
- All names in both resources and variables should follow the [Snake Case](https://en.wikipedia.org/wiki/Snake_case) naming convention.

### Ansible

Our Ansible code follows a simple encapsulation approach primarily through [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) and strong usage of [Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html) and [Templates](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html).

To recap there are five main concepts for Ansible:

- [Inventories](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) - List of machines that Ansible will run against. Typically we use [Dynamic Inventories](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html) in the Toolkit that build the list of machines automatically based on machine labels (set by Terraform).
- [Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html) - Effectively our "runners", the playbooks select what machines to run on and what Role to run on them
- [Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) - The bulk of our code. Roles generally correspond to a GitLab component or a collection of actions and contain all of the actions required to setup that component. Some Roles are more specialized in that they run on all nodes regardless or on `localhost` when required.
- [Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html) - Variables are used throughout the code in both execution and file templates for GitLab config. All configurable by the user.
- [Templates](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) - Templates are also used throughout in both Variable expansion and to configure config files on the target nodes.

Utilizing the above the run flow of our code in Ansible is as follows:

- Inventories list the machines with categories based on the labels they already have applied in our Terraform modules.
- Variables are constructed at runtime, pulling from Inventory, Group and Roles. See the [Variables](#variables) section for more info.
- Playbooks select nodes based on the above mentioned labels and run the corresponding Role(s) in the correct order required for GitLab.
- Role(s) run tasks on the selected nodes in order, utilizing the constructed Variables or any specific files they have as required.

Some general implementation rules we follow for Ansible:

- Roles should only be added when there's a clear need for them and they have a good purpose. This is to prevent code fragmentation that in turn will impact maintainability.
- It's allowed to repeat select tasks or config across Roles following the principle of [AHA](#aha-avoid-hasty-abstractions). Tasks should be viewed as equivalent to function calls.

#### Variables

[Ansible's variable precedence](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable) can be hard to work with, especially with an Inventory led variable design like the Toolkit's where the goal is for users to pass in their own (overriding) config for each environment.

Previously the Toolkit was created with a Group Vars led design, this has now changed to Role Defaults to better fit Ansible's default precedence.

For the Toolkit, variables must be placed in one of three places depending on their scope to ensure correct precedence as follows:

- Common Vars Role Defaults (`common_vars/defaults/main.yml`) - For any variables that are to be used in more than one Role. All Roles and Playbooks pull this role in as a dependency for this purpose.
- Specific Role Defaults (`<role_name>/defaults/main.yml`) - For any variables that are used in a single role only.
- Group Defaults (`group_vars/<group_name>.yml`) - For any variables that should be applied for a group of nodes.

#### Version Support

We support Ansible versions from `2.9.*` onwards. From time to time we may bump up this minimum supported version as required with adequate notice to users.

#### Styling

- Ansible code should pass the project's lint checks. We utilize [`ansible-lint`](https://github.com/ansible-community/ansible-lint) and a customized [rules list](ansible/.ansible-lint).
- Variables follow the [Snake Case](https://en.wikipedia.org/wiki/Snake_case) naming convention. In addition to this variables for components typically should follow the convention of `<component>_*` to allow for easier readability and consistency of variables per component.

### General

#### Run as Source

Currently the Toolkit is designed to be run as source, i.e. to run with the direct Terraform and Ansible commands.

This allows for certain flexibility with the Tools that would be lost if we published them as "modules" to their respective registries, such as setting Ansible config. A [Docker image is currently planned to be released that maintains these needs](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/issues/56).

This design is under review however and we'll look to reevaluate if its possible to publish both our Terraform and Ansible code into the respective registries ([Terraform](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/issues/205), [Ansible](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/issues/206)).

#### Releases and Supported GitLab Versions

The following rules apply for Toolkit releases and support between them:

- The Toolkit follows [Semantic Versions](https://semver.org/) where we release Major, Minor and Patch versions via [project releases](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/releases).
- Releases are not tied directly to GitLab versions, we currently support GitLab versions from `13.2` onwards.
- Breaking changes such as minimum supported GitLab version may be changed in Major releases with adequate notice and an upgrade path given to users.
- We aim to support Backwards Compatibility between minor releases. Although some small breaking changes may be added with adequate notice if the need is justified.
- Backwards Compatibility is not guaranteed for in development code on the main branch.

#### Secrets and Keys

Any Secrets and/or Keys for use with the Toolkit are expressly forbidden to be committed in the repo.

The Toolkit has been designed to allow users to add in these via configuring file paths or environment variables accordingly.

#### User Accounts

We expressly avoid the management of User Accounts in the Toolkit wherever possible. This extends to system accounts provided by the Cloud Providers.

This is due to User Accounts being subject to various considerations in regards to security and auditing depending on the company. The Toolkit expects accounts to be created separately as per the required process and passed in where appropriate.
