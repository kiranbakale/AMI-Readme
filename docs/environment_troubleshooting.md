# Troubleshooting

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Monitoring](environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [**GitLab Environment Toolkit - Troubleshooting**](environment_troubleshooting.md)

On this page you'll find troubleshooting guidance for various areas when using the GitLab Environment Toolkit.

[[_TOC_]]

## Terraform

### GCP Resource Creation Error - `Error 400: The resource '<subnetwork>' is not ready, resourceNotReady`

In select GCP setups you may see Terraform throw the following error on the first creation:

```sh
Error: Error creating instance: googleapi: Error 400: The resource 'projects/gitlab-qa-10k-cd77c7/regions/us-east1/subnetworks/default' is not ready, resourceNotReady
```

This looks to be a race condition issue on Google's end and is [currently being investigated by them](https://github.com/hashicorp/terraform-provider-google/issues/10972).

This error only happens once and rerunning should succeed without issue.

## Ansible

### Ansible Install Failure - `No matching distribution found`

Ansible `6.x` upwards requires Python `3.8` and higher. Attempting to install this version of Ansible via `pip` on a lower version of Python will fail with the following error:

```sh
ERROR: No matching distribution found for ansible==5.0.1
```

Upgrade your Python version to `3.8` or higher and try installing again to fix.

### Ansible can't find any hosts

Ansible uses a dynamic inventory, which allows it to discover hosts by
matching their names with your environment's prefix. If your Ansible
scripts are unable to find any matching hosts, check that `prefix` is
set properly across all YAML files. For example, for the 10K AWS
example, check:

1. `all.vars.prefix` in `vars.yml`
1. `gitlab_node_prefix` in `10k.aws_ec2.yml`

Also check that your cloud access credentials are correctly specified
in the environment. You can use `ansible-inventory` to see which
hosts Ansible has found:

```shell
ansible-inventory -i environments/10k/inventory --graph
```

Sample output:

```plaintext
@all:
  |--@aws_ec2:
  |  |--mytest-consul-1
  |  |--mytest-consul-2
  |  |--mytest-consul-3
  |  |--mytest-gitaly-1
  |  |--mytest-gitlab-nfs-1
  |  |--mytest-monitor-1
  |  |--mytest-praefect-1
  |--@consul:
  |  |--mytest-consul-1
  |  |--mytest-consul-2
  |  |--mytest-consul-3
  |--@gitaly:
  |  |--mytest-gitaly-1
  |--@gitaly_primary:
  |  |--mytest-gitaly-1
  |--@gitlab:
  |--@gitlab_nfs:
  |  |--mytest-gitlab-nfs-1
  |--@global:
  |--@monitor:
  |  |--mytest-monitor-1
  |--@nginx-ingress:
  |--@praefect:
  |  |--mytest-praefect-1
  |--@praefect_primary:
  |  |--mytest-praefect-1
  |--@ungrouped:
```

You can also troubleshoot Ansible issues by using `ansible-inventory` to
show the configuration for specific hosts from. For example, suppose in
the above example you wanted to display what Ansible has loaded for
`mytest-gitaly-1`. The following command would show JSON data for many
of the variables used in the playbooks:

```shell
ansible-inventory -i environments/10k/inventory --graph --host mytest-gitaly-1
```

### Postgres Upgrade Error - `PostgreSQL did not respond before service checks were exhausted`

The following error can show when running the Toolkit on PostgreSQL nodes:

```sh
ruby_block[wait for postgresql to start] (patroni::enable line 105) had an error: RuntimeError: PostgreSQL did not respond before service checks were exhausted
```

This is due to a [rare application issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5969) where the specific Secondary Postgres server has become corrupted and unable to sync replication with the Primary server, causing it to enter a restart loop.

If you examine the specific Postgres server's logs (`/var/log/gitlab/patroni/current`) you'll likely see the real error as follows:

```sh
LOG:  invalid resource manager ID in primary checkpoint record
PANIC:  could not locate a valid checkpoint record
/var/opt/gitlab/postgresql:5432 - rejecting connections
FATAL:  the database system is starting up
/var/opt/gitlab/postgresql:5432 - rejecting connections
FATAL:  the database system is starting up
LOG:  startup process (PID 3711) was terminated by signal 6: Aborted
LOG:  aborting startup due to startup process failure
```

To fix this you need to reset the WAL log on the specific server as follows:

```sh
sudo su - gitlab-psql -c '/opt/gitlab/embedded/bin/pg_resetwal -f /var/opt/gitlab/postgresql/data'
```

:warning:&nbsp; This command deletes the current record and as such may lead to data loss. It should only be run on the specific server with the corrupted log.

This wipes the records from the specific server and will unblock it to start replicating again. This should **only** be run on the specific Secondary server that is failing and no others as this would lead to data loss.

## Cloud Native Hybrid

In this section are troubleshooting steps for some common Cloud Native Hybrid environment issues.

For these setups, it's worth noting that they have quite a few moving parts, all of which could cause a failure. For example, Ansible doesn't configure the Kubernetes components directly, instead deploying the [Helm Charts](https://docs.gitlab.com/charts/) that in turn instruct Kubernetes on what to set up. The Charts contain various checks and pre-actions that can subsequently fail internally. Additionally, some setup happens at the Cloud Provider level that can also fail internally.

With that context, some of the more common failures are listed below with troubleshooting steps.

### Environment not resolvable on URL

If, after the Charts have been deployed, the environment isn't resolving on its URL as expected you may see the following error later in the Toolkit run:

```sh
TASK [post_configure : Wait for GitLab to be available] *********************************************************************************************************************************
fatal: [localhost]: FAILED! => changed=false
  attempts: 20
  cache_control: no-cache
  connection: close
  content_length: '107'
  content_type: text/html
  elapsed: 0
  msg: 'Status code was 503 and not [200]: HTTP Error 503: Service Unavailable'
```

This error is due to the Toolkit doing a sanity check to see if the setup has been successful after deploying the Helm Charts. When this error is thrown, it means that the deployment failed to complete for some reason.

Some common reasons for this may be:

- Double check that `cloud_native_hybrid_environment` and `kubeconfig_setup` are enabled to instruct the Toolkit to deploy the Charts
- AWS EKS has failed to configure the AWS Load Balancer (which it manages directly) due to not enough Elastic IPs being given via the [`aws_allocation_ids` setting](environment_advanced_hybrid.md#amazon-web-services-aws-1) - There should be one for every Subnet.
- Webservice / Sidekiq pods have failed to deploy due to one of their pre-actions or checks failing. [See the below Webservice / Sidekiq Pods not deploying section for more info](#webservice--sidekiq-pods-not-deploying).

### Webservice / Sidekiq Pods not deploying

There may be times when the Webservice / Sidekiq pods may not deploy on the target Kubernetes cluster even though the Toolkit has completed "successfully". While Ansible has been successful in giving the _instruction_ via the Helm Charts to deploy said pods, something such as any pre-actions or additional checks that happen in Kubernetes have failed to complete.

The pod's pre-actions or additional checks, done via [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), act as a sanity check for the whole environment and if anything is wrong they will fail to deploy. These include running checks such as if the backends can be connected to or performing configuration. When this is the case, you may see the `Init:CrashLoopBackOff` error being thrown in Kubernetes when you run commands such as `kubectl get pods`.

Typically, this is due to a misconfiguration, specifically that the pods have failed to connect to the backends. To debug further, the following steps are recommended:

- Double check that the [configuration](environment_advanced_hybrid.md#4-configuring-the-helm-charts-deployment-with-ansible) is correct. Some examples:
  - If using any external services ([RDS](environment_advanced_services.md#configuring-with-ansible-1) / [ElastiCache](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_advanced_services.md#configuring-with-ansible-2) / [Internal LB](environment_advanced_services.md#configuring-with-ansible)) that the config for each has been added for the environment to use them.
- [Debug the Init Containers](https://kubernetes.io/docs/tasks/debug/debug-application/debug-init-containers/). In particular checking the logs of each Init Container may prove to be very useful as errors thrown by these containers aren't typically surfaced. An example of how this can be done as follows:
  - Get the name of any `webservice` pods - `kubectl get pods -l app=webservice`
  - Using that name, retrieve the list of its Init Container names - `kubectl get pod <WEBSERVICE_POD_NAME> -o jsonpath={.spec.initContainers[*].name}`
  - Look through the logs of each container for any errors - `kubectl logs <WEBSERVICE_POD_NAME> -c <INIT_CONTAINER_NAME>`

If the issue is still not found after the above steps, [further debugging guidance can be found in the Charts documentation](https://docs.gitlab.com/charts/troubleshooting/index.html#application-containers-constantly-initializin).

### `Could not match supplied host pattern, ignoring: gitlab_cluster` Warning

Depending on the Toolkit version you may see the following warning being thrown by Ansible at the beginning of its run:

```sh
[WARNING]: Could not match supplied host pattern, ignoring: gitlab_cluster
```

[This warning is due to an Ansible quirk](https://github.com/ansible/ansible/issues/40030) and can be ignored.

For some background, GKE / EKS will set up VMs to be the Nodes in the Kubernetes cluster. These VMs show up in normal lists and can appear in Ansible Inventories as a result. Ansible can't configure these nodes directly that are instead managed by GKE / EKS, which Ansible configures later via Helm. As such, depending on cloud provider, Ansible is configured to ignore these machines directly and this can sometimes result in the above warning.

From GitLab Environment Toolkit version `2.4.0` onwards this warning is disabled by default as it's expected.

### Data missing in environment after successful deploy

After deployment if there appears to be data missing, such as missing Users, this is likely due to [Database Migrations](https://docs.gitlab.com/charts/charts/gitlab/migrations/) not completing successfully.

In the Charts this is done via a specific Job named `migrations`. If it's failing it's likely due to it not being able to access the database correctly.

[The debugging steps in this section of the Chart's documentation](https://docs.gitlab.com/charts/troubleshooting/#application-containers-constantly-initializing) can be followed to debug further.

## Other

### macOS - Python package install failure - `fatal error: 'openssl/opensslv.h' file not found`

For macOS users, installation of Python packages via `pip3 install` may fail with an error:

```plaintext
fatal error: 'openssl/opensslv.h' file not found
```

You may first need to set up compiler flags to point to OpenSSL:

```shell
brew install openssl@1.1 rust
export LDFLAGS="-L$(brew --prefix openssl@1.1)/lib"
export CFLAGS="-I$(brew --prefix openssl@1.1)/include"
```

For more details, see:

1. [Documentation on installing the cryptography Python package](https://cryptography.io/en/latest/installation/#building-cryptography-on-macos)
1. [Discussion in GitHub issue](https://github.com/pyca/cryptography/issues/3489#issuecomment-318070912)
