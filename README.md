# AMI GitLab Modernization

![MicrosoftTeams-image (89)](https://github.com/kiranbakale/AMI-Readme/assets/46279617/3d82fa9f-cac2-452c-8276-70810b5d0976)


Created and maintained by the Minfy team, the Guide supports the following features:

- Support for deploying architecture sizes dynamically upto [5k](https://docs.gitlab.com/ee/administration/reference_architectures/5k_users.html).
- Support for deploying Cloud Native Hybrid variants of the Reference Architectures (AWS).
- Alternative sources (Cloud Services, Custom Servers) for select components (Load Balancers, PostgreSQL, Redis)
- Custom Config / Tasks / Files support

## Before You Start

It's recommended that users have a good working knowledge of Terraform, Ansible, GitLab administration as well as running applications at scale in production before using the Toolkit.

While the Toolkit does aim to streamline the process notably, the same underlying challenges still apply when running applications at scale. For users who aren't in this position, our [Professional Services](https://about.gitlab.com/services/#implementation-services) team offers implementation services, but for those who want a more managed solution long term, it's recommended to instead explore our other offerings such as [GitLab SaaS](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) or [GitLab Dedicated](https://about.gitlab.com/dedicated/).

If you are interested in using the Toolkit, it's strongly recommended that you independently review the Toolkit in full to ensure it meets your requirements, especially around [security](docs/environment_post_considerations.md#security). [Further manual setup](docs/environment_post_considerations.md) will also still likely be required based on your specific requirements.

## Requirements

The requirements for the Toolkit are as follows:

- GitLab version: `15.10.0` and upwards.
- OS: Canonical, Ubuntu, 22.04 LTS, Debian 11, RHEL 8, Amazon Linux 2
  - At this time the Toolkit only supports clean OS installations..
  - ARM based hardware is supported for Omnibus environments
- Types of environment: The Toolkit is designed to deploy the official GitLab [Reference Architectures](https://docs.gitlab.com/ee/administration/reference_architectures) (Standard or Cloud Native Hybrid) as environments.
  - The Toolkit requires [NFS to propagate certain files](docs/environment_advanced.md#nfs-options). This can be on a dedicated node, or it will dynamically set this up on other nodes as required.

## Tools used


## Documentation

- [GitLab Environment Toolkit - Quick Start Guide](docs/environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](docs/environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](docs/environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](docs/environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](docs/environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](docs/environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](docs/environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](docs/environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](docs/environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Geo](docs/environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](docs/environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](docs/environment_upgrades.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](docs/environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](docs/environment_troubleshooting.md)

### Config Examples

[Full config examples are available for select Reference Architectures](examples).

## How To Use



--

## How It Works



![MicrosoftTeams-image (85)](https://github.com/kiranbakale/AMI-Readme/assets/46279617/0246fdfa-7694-4576-b7e7-9bddf7a3e295)




- The Cloud Native GitLab architecture on Amazon EKS (Elastic Kubernetes Service) is designed to support a large-scale deployment of GitLab for ~5000 users.
- The hybrid installation of GitLab combines predominantly stateless components (Webservice, Sidekiq) with a few stateful ones (Gitaly, Praefect). Stateless components will be deployed in a Kubernetes (EKS) cluster, while stateful components will utilize traditional compute resources (EC2 instances) for persistence.
- Additionally, NGINX, Task Runner, Migrations, Prometheus, and Grafana will also run on the EKS cluster. The database will be hosted on RDS, and cache/queue services will leverage ElastiCache.
-	GitLab is deployed as a set of containerized services within a Kubernetes cluster, leveraging the scalability and flexibility of EKS.
-	Deploy the core GitLab application along with supporting services such as PostgreSQL database, Redis caching, and object storage.
-	Gitlab runner to be deployed on fargate to provision dedicated containers for running CI/CD pipelines.
-	Implementing a backup strategy to regularly backup GitLab data, including repositories, configuration, and databases, to a secure and separate storage location.


## DEVOPS WORKFLOW
### INFRA PROVISIONING USING TERRAFORM
-	Set up a bastion host to establish secure connections between the EKS cluster and the private instances.
-	Provision the necessary infrastructure resources, including networking, storage, EKS, EC2, RDS, IAM roles, ELB, Elastic Cache, security, Gitaly and Praefect nodes.
-	Setup the environments configs.
-	‘ref_arch’ module per host provider and for each there are 3 config files to set up
-	‘main.tf’ - Contains the main Terraform connection settings such as cloud provider or state backend.
-	 `environment.tf` - `ref_arch` module configuration (machine count or sizes for example).
-	`variables.tf` - Variable definitions.
-	After configuring the settings, apply Terraform to provision all the necessary resources.

### CONFIGURATION MANAGEMENT
-	Employ Ansible to configure and manage the components of GitLab.
-	Develop Ansible roles to automate the configuration of Gitaly and Praefect nodes.
-	Setup the inventory and config
-	Create vars.yml in inventory and retrieve all the passwords, connection settings variables from the secret manager.
-	From the playbook create the kubernetes secrets for gitaly_token, praefect_internal_token, Praefect_external_token, gitlab_shell_token, postgres_password to configure the same tokens in the gitaly and praefect nodes
-	Run ‘ansible-playbook’ with inventory against ‘all.yml’ playbook

### CONTAINERIZATION AND ORCHESTRATION
-	Deploy GitLab as containers in a Kubernetes cluster using Helm charts and Gitlab runner to be deployed on fargate.
-	Deploy the Helm chart using an Ansible playbook by providing a custom configuration values file that merges with the existing default template.

### NETWORKING AND SECURITY
- To expose ingress controller’s endpoint to the external users, configure the hosted zone.
-	Implement Guard Duty in a cloud-native deployment of GitLab using Helm is to enhance the security posture of your GitLab environment.







## Troubleshooting

Please refer to our [Troubleshooting guide](docs/environment_troubleshooting.md) if you are having issues deploying an environment with the Toolkit.

[Technical support](https://about.gitlab.com/support/) for troubleshooting issues is only available for the current Toolkit major version.

## Feature Requests

Feature Requests can be raised in [our tracker](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/issues). Please check beforehand to see if a request already exists (and upvote in that case).

### Features that won't be covered

Due to complexities, permutations or areas best left to be configured directly we do not plan to include the following:

- Cloud accounts management
- Observability stack beyond Prometheus and Grafana
- Direct OmniAuth and Email support
- DNS server management
- Full GitLab agent server for Kubernetes (KAS) setup

The above areas are better tackled via [Custom Config](docs/environment_advanced.md#custom-config).

### Contributions

This project accepts contributions to existing features. Refer to the [Contributing guide](CONTRIBUTING.md) for more information.

## Licensing

Requires [GitLab Premium](https://about.gitlab.com/pricing/) or above.

Released under the [GitLab EE license](LICENSE).
