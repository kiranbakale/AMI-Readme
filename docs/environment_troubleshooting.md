# Troubleshooting

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [**GitLab Environment Toolkit - Troubleshooting**](environment_troubleshooting.md)

On this page you'll find troubleshooting guidance for various areas when using the GitLab Environment Toolkit.

[[_TOC_]]

## Ansible Install Failure - `No matching distribution found`

Ansible `5.x` requires Python `3.8` and higher. Attempting to install this version of Ansible via `pip` on a lower version of Python will fail with the following error:

```sh
ERROR: No matching distribution found for ansible==5.0.1
```

Upgrade your Python version to `3.8` or higher and try installing again to fix.

## Python package install failure - `fatal error: 'openssl/opensslv.h' file not found`

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

## Postgres Upgrade Error - `PostgreSQL did not respond before service checks were exhausted`

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

## GCP Resource Creation Error - `Error 400: The resource '<subnetwork>' is not ready, resourceNotReady`

In select GCP setups you may see Terraform throw the following error on the first creation:

```sh
Error: Error creating instance: googleapi: Error 400: The resource 'projects/gitlab-qa-10k-cd77c7/regions/us-east1/subnetworks/default' is not ready, resourceNotReady
```

This looks to be a race condition issue on Google's end and is [currently being investigated by them](https://github.com/hashicorp/terraform-provider-google/issues/10972).

This error only happens once and rerunning should succeed without issue.

## Ansible can't find any hosts

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
