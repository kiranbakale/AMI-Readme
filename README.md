# GitLab Environment Toolkit

The GitLab Environment Toolkit (`GET`), formerly known as the Performance Environment Builder, is a collection of tools with a simple purpose - to deploy [GitLab Omnibus](https://gitlab.com/gitlab-org/omnibus-gitlab) at scale as per our [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures).

Created and maintained by the Quality team the Toolkit, built with [Terraform](https://www.terraform.io/) and [Ansible](https://docs.ansible.com/ansible/latest/index.html), supports provisioning and configuring machines respectively with the following features:

* Support for deploying all [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) sizes dynamically from [1k](https://docs.gitlab.com/ee/administration/reference_architectures/1k_users.html) to [50k](https://docs.gitlab.com/ee/administration/reference_architectures/50k_users.html).
* GCP and Azure cloud provider support
* Upgrades
* Release and nightly Omnibus builds support
* Advanced search with Elasticsearch
* Load Balancing and Monitoring setup
* Support for new and incoming features such as Patroni

Originally built to help define the official [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) and enable performance testing against those with the [GPT](https://gitlab.com/gitlab-org/quality/performance), the Quality team use this Toolkit pretty much daily and it's now open to be used by other teams to enable them to deploy GitLab at scale in the recommended way.

## How It Works

At a high level the Toolkit is designed to be as simple as possible. A high level overview of how it works is as follows:

* Machines are provisioned as per the [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) with Terraform with Labels added to each for Ansible to then identify
* Ansible, through identifying each machine by its Labels, will intelligently go through them in the GitLab install order. On each it will install and configure Omnibus to setup the intended component as required. Further to this Ansible will ignore missing machines allow for more dynamic setups (e.g. an environment without Elasticsearch, or a small 1k environment with a smaller amount of nodes).
* Additional tasks are also performed as required such as setting GitLab config through API, Load Balancer setup and additional monitoring setup.

## Documentation

* [Preparing the toolkit](docs/prep_toolkit.md)
* [Building environment(s)](docs/building_environments.md)

## Issues or Feature Requests

Everyone is welcome to open new Issues or Feature Requests (or to upvote existing ones) over on our tracker [here](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/issues).

Further information:

* Work in progress can also be seen on our [board](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/boards).
* Issues relating directly to the [Reference Architectures can be found in their own project](https://gitlab.com/gitlab-org/quality/reference-architectures).
* Issues relating to the previous incarnation of Performance Environment Builder can be found on the old generic performance issue tracker [here](https://gitlab.com/gitlab-org/quality/performance/-/issues?scope=all&utf8=%E2%9C%93&state=closed).
* To contact the team you can also reach out on Slack [#gitlab-environment-toolkit](https://gitlab.slack.com/archives/C01DE8TA545) channel.
