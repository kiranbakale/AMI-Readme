This directory is for storing the various keys needed to run the builder to build environments. This includes GCP Service Account, SSH and License keys. Refer to the main [docs](../README.md#documentation) for more info.

If you're using the builder to build your own environment(s) you can store your keys here in this directory and configure Terraform and Ansible to load them keys accordingly.

The [`git-crypt`](https://github.com/AGWA/git-crypt) encrypted `performance` directory contains all the keys for live Quality test environments that are used for automated performance testing. Access to this folder is only required when you're expected to update or maintain these environments. Contact the Quality Enablement team if this is the case.