# GitLab Environment Toolkit

> Requires [GitLab Premium](https://about.gitlab.com/pricing/) or above.
> Released under the [GitLab EE license](LICENSE).

The GitLab Environment Toolkit (`GET`) is a collection of tools with a simple focused purpose - to deploy [GitLab Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab) at scale as defined by our [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures).

Created and maintained by the Quality Enablement team the Toolkit, built with [Terraform](https://www.terraform.io/) and [Ansible](https://docs.ansible.com/ansible/latest/index.html), supports provisioning and configuring machines respectively with the following features:

- Support for deploying all [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) sizes dynamically from [1k](https://docs.gitlab.com/ee/administration/reference_architectures/1k_users.html) to [50k](https://docs.gitlab.com/ee/administration/reference_architectures/50k_users.html).
- Support for deploying Cloud Native Hybrid variants of the Reference Architectures (GCP only at this time).
- GCP, AWS and Azure cloud provider support
- Upgrades
- Release and nightly Omnibus builds support
- Advanced search with Elasticsearch
- Built in Load Balancing and Monitoring (Prometheus, Grafana) setup

Originally built to help define the official [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) and enable performance testing against those with the [GPT](https://gitlab.com/gitlab-org/quality/performance), the Toolkit has been opened to be used by other teams to enable them to deploy GitLab at scale in the recommended way.

## How It Works

At a high level the Toolkit is designed to be as straightforward as possible. A high level overview of how it works is as follows:

- Machines are _provisioned_ as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) with Terraform. Part of this provisioning includes adding specific labels / tags to each machine for Ansible to then use to identify.
- Machines are _configured_ with Ansible. Through identifying each machine by its Labels, Ansible will intelligently go through them in the correct install order. On each it will install and configure Omnibus to setup the intended component as required. The Ansible scripts have been designed to handle certain dynamic setups depending on what machines have been provisioned (e.g. an environment without Elasticsearch, or a 2k environment with a smaller amount of nodes). Additional tasks are also performed as required such as setting GitLab config through API or Load Balancer and Monitoring setup.

## Requirements

Note that the Toolkit currently has the following requirements (with related issues to increase support further):

- GitLab version: `13.2.0` and upwards. ([GitLab version support issue](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/issues/35)).
- OS: Ubuntu 18.04 ([OS support issue](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/issues/43))
  - Note that additionally at this time GET supports clean Ubuntu installs and may work with existing ones but this is not guaranteed at this time.
  - Admin access to the OS is also required by GET to install various dependencies
- Types of environment: The Toolkit is designed to deploy the official GitLab [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) as environments.
  - Advanced usage is possible where users can make tweaks to the environments as desired, such as increasing the number of nodes or their specs, but this is generally unrecommended.

## Documentation

- [GitLab Environment Toolkit - Preparing the environment](docs/environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](docs/environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](docs/environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Customizations](docs/environment_advanced.md)
  - [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](docs/environment_advanced_hybrid.md)

## Issues or Feature Requests

Everyone is welcome to open new Issues or Feature Requests (or to upvote existing ones) over on our tracker [here](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/issues).

Further information:

<!-- markdownlint-disable proper-names -->
- Work in progress can also be seen on our [board](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/boards).
- Issues relating directly to the [Reference Architectures can be found in their own project](https://gitlab.com/gitlab-org/quality/reference-architectures).
- Issues relating to the previous incarnation of Performance Environment Builder can be found on the old generic performance issue tracker [here](https://gitlab.com/gitlab-org/quality/performance/-/issues?scope=all&utf8=%E2%9C%93&state=closed).
- To contact the team you can also reach out on Slack [#gitlab-environment-toolkit](https://gitlab.slack.com/archives/C01DE8TA545) channel.
<!-- markdownlint-restore proper-names -->
