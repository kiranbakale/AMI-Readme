# Advanced - External SSL

- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [**GitLab Environment Toolkit - Advanced - External SSL**](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Cloud Services](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [GitLab Environment Toolkit - Advanced - Custom Config, Data Disks, Advanced Search and more](environment_advanced.md)
- [GitLab Environment Toolkit - Upgrade Notes](environment_upgrades.md)
- [GitLab Environment Toolkit - Legacy Setups](environment_legacy.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)

The Toolkit supports automatically configuring your environment with [External SSL termination](https://docs.gitlab.com/ee/administration/load_balancer.html#load-balancers-terminate-ssl-without-backend-ssl). 

This is supported for both Standard and Cloud Native Hybrid Reference Architectures where HAProxy or NGINX Ingress respectively will be configured to handle SSL termination.

To enable this functionality SSL Certificates are required. The Toolkit supports two sources of certificates: **User provided** or automated via [**Let's Encrypt**](https://letsencrypt.org/).

On this page we detail how to configure External SSL termination with either source. **It's worth noting this guide is supplementary to the rest of the docs and it will assume this throughout.**

[[_TOC_]]

## Overview

With External SSL termination, the external entry point for the environment will encrypt connections to and from all users and then decrypt these to pass onto the GitLab environment's components. This offers a good level of security while balanced against reduced complexity.

When External SSL termination is enabled the following should be noted:

- The main GitLab application as well as Grafana will be served externally via `https`. Any requests made to these over `http` will be redirected to `https`.
- Other accessible endpoints such as HAProxy stats will still be served over `http`.

Below are the details on how to set this up with either source.

## 1. Prepare Certificates and Toolkit

The first step is to prepare files and \ or config for the Toolkit.

The steps for this differ depending on certificate source - head to the section below that's for your selected source:

- [User provided certificates](#user-provided-certificates)
- [Let's Encrypt generated certificates](#lets-encrypt-generated-certificates)

### User provided certificates

For users who already have certificates for their intended GitLab environment the Toolkit can use these as given to set up External SSL termination.

At a high level the Toolkit will simply take the certificate and key files and use them to configure HAProxy (Standard) or NGINX Ingress (Cloud Native Hybrid) respectively to use them. Below are the steps to configure this.

#### Setup user provided certificates for Toolkit use

The first step is to provide the certificates themselves for the Toolkit to use. By default the Toolkit expects the following:

- That certificate and key files are located in the `ansible/environments/<env_name>/files/certificates` folder
- That certificate and key files are named in the formats `<hostname>.pem` and `<hostname>.key` respectively.
  - `pem` is used here by default as this is now the typically used standard across various tools such as HAProxy \ Let's Encrypt, etc...
- That the certificate file contains the [full chain](https://www.digicert.com/kb/ssl-support/pem-ssl-creation.htm)

You can optionally store your SSL files in a different location as well as use different names if desired with additional configuration. This will be detailed further in the next section.

Once the SSL certificate and key files are in the desired location you can proceed to the next step.

#### Configure Variables for user provided certificates

After the SSL certificate and key are in place you then need to configure the Toolkit to use them. This is done as normal in Ansible via the Inventory Variables.

There are two main variables to set in the Inventory Variables `vars.yml` file that configures the Toolkit to use External SSL termination with user provided certificates:

- `external_url` - Set [previously](environment_configure.md) this is the main URL the environment is expected to be reached on. For External SSL termination this should be changed to a url that starts with `https://`.
- `external_ssl_source` - Sets what source is being used for the External SSL certificates. In this setup it should be set to `user`.

When the certificates are configured as the Toolkit expects then, as detailed in the previous section, an example of how the config would look is as follows:

```yml
all:
  vars:
    [...]
    external_url: "https://<hostname>"
    external_ssl_source: "user"
```

If the files are stored in another location or have a different name, the following variables are available to customize where the Toolkit will look for the files:

- `external_ssl_files_host_certificate_file` - Set to the full file path of the certificate on the host machine running Ansible. Note that with this setting you can also pass in a path to a `.crt` file if desired as the contents are the same as a `.pem` file.
- `external_ssl_files_host_key_file` - Set to the full file path of the key on the host machine running Ansible.

Once the config is in place you're ready to [configure the environment](#2-configure-the-environment).

### Let's Encrypt generated certificates

[Let's Encrypt](https://letsencrypt.org/) allows users to generate signed SSL certificates for free. The Toolkit allows for these generated certificates to be used for External SSL termination instead of user provided ones.

At a high level the Toolkit will either directly use [`certbot`](https://certbot.eff.org/) to generate the files then configure HAProxy (Standard) or configure Helm to use `certbot` and configure NGINX Ingress (Cloud Native Hybrid) instead. Below are the steps to configure this.

#### Configure Variables

As the certificates are generated automatically via Let's Encrypt the Toolkit only needs to be configured to use them.

There are three main variables to set in the Inventory Variables `vars.yml` file that configures the Toolkit to use External SSL termination with Let's Encrypt certificate:

- `external_url` - Set [previously](environment_configure.md) this is the main URL the environment is expected to be reached on. For External SSL termination this should be changed to a url that starts with `https://`.
- `external_ssl_source` - Sets what source is being used for the External SSL certificates. In this setup it should be set to `letsencrypt`.
- `external_ssl_letsencrypt_issuer_email` - Email to use with Let's Encrypt as recommended to associate with certificates for renewal and recovery. This should be set to an email of an administrator of the GitLab environment to manage certificates.

An example of how the config would look is as follows:

```yml
all:
  vars:
    [...]
    external_url: "https://<hostname>"
    external_ssl_source: "letsencrypt"
    external_ssl_letsencrypt_issuer_email: "admin@example.com"
```

Once the config is in place you're ready to [configure the environment](#2-configure-the-environment).

## 2. Configure the environment

With the files and config in place all that's left is to update the environment. This can be done [the same as a normal environment update](environment_configure.md#3-configure-update).

As an alternative you can also just reconfigure the specific nodes, depending on the type of environment, that will avoid doing a version update of GitLab as follows:

- Standard - `ansible-playbook -i environments/10k/inventory haproxy.yml gitaly.yml gitlab-rails.yml -t reconfigure`
- Cloud Native Hybrid - `ansible-playbook -i environments/10k/inventory gitaly.yml gitlab-charts.yml -t reconfigure`
