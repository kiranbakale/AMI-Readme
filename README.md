# GitLab Performance Environment Builder

Terraform and Ansible toolkit for building and updating GitLab [Reference Architecture](https://docs.gitlab.com/ee/administration/scaling/#reference-architectures) environments (latest version) on Google Cloud Platform (GCP) or Microsoft Azure for large scale setup validation and performance testing.

At the time of writing we have the following environments that are currently being built and maintained with this toolkit:

* [1k](https://console.cloud.google.com/home/dashboard?project=gitlab-qa-1k-0917a1)
* [2k](https://console.cloud.google.com/home/dashboard?project=gitlab-qa-2k-ca9f9e)
* [5k](https://console.cloud.google.com/home/dashboard?project=gitlab-qa-5k-0ee8fa)
* [10k](https://console.cloud.google.com/home/dashboard?project=gitlab-qa-10k-cd77c7)
* [25k](https://console.cloud.google.com/home/dashboard?project=gitlab-qa-25k-bc38fe)
* [50k](https://console.cloud.google.com/home/dashboard?project=gitlab-qa-50k-193234)

The Toolkit consists of two industry standard tools:

* [Terraform](https://www.terraform.io/) - To provision environment infrastructure
* [Ansible](https://docs.ansible.com/ansible/latest/index.html) - To configure GitLab on the provisioned infrastructure

## Documentation

GCP:

* [Preparing the toolkit](docs/prep_toolkit.md)
* [Building environment(s)](docs/building_environments.md)

Azure:

* [Preparing the toolkit](docs/azure/prep_toolkit.md)
* [Building environment(s)](docs/azure/building_environments.md)

## Raising Issues

For any Issues with the builder please raise them on our main [performance project](https://gitlab.com/gitlab-org/quality/performance/-/issues).
