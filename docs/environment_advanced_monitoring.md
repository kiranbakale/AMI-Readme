# Advanced - Monitoring

- [GitLab Environment Toolkit - Quick Start Guide](environment_quick_start_guide.md)
- [GitLab Environment Toolkit - Preparing the environment](environment_prep.md)
- [GitLab Environment Toolkit - Provisioning the environment with Terraform](environment_provision.md)
- [GitLab Environment Toolkit - Configuring the environment with Ansible](environment_configure.md)
- [GitLab Environment Toolkit - Advanced - Custom Config / Tasks / Files, Data Disks, Advanced Search, Container Registry and more](environment_advanced.md)
- [GitLab Environment Toolkit - Advanced - Cloud Native Hybrid](environment_advanced_hybrid.md)
- [GitLab Environment Toolkit - Advanced - Component Cloud Services / Custom (Load Balancers, PostgreSQL, Redis)](environment_advanced_services.md)
- [GitLab Environment Toolkit - Advanced - SSL](environment_advanced_ssl.md)
- [GitLab Environment Toolkit - Advanced - Network Setup](environment_advanced_network.md)
- [GitLab Environment Toolkit - Advanced - Geo](environment_advanced_geo.md)
- [**GitLab Environment Toolkit - Advanced - Monitoring**](environment_advanced_monitoring.md)
- [GitLab Environment Toolkit - Upgrades (Toolkit, Environment)](environment_upgrades.md)
- [GitLab Environment Toolkit - Considerations After Deployment - Backups, Security](environment_post_considerations.md)
- [GitLab Environment Toolkit - Troubleshooting](environment_troubleshooting.md)

The Toolkit supports setting up optional monitoring of the environment of metrics such as CPU and Memory as well as GitLab specific metrics.

:information_source:&nbsp; Note that the following monitoring setups are optional. You're not required to use this functionality for monitoring your environment, and you can use a different setup as desired.

:information_source:&nbsp; As of GitLab 16.0, [Omnibus-bundled Grafana is deprecated](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#deprecation-of-bundled-grafana), and scheduled for removal from Omnibus in 16.3. This change does **not** affect the monitoring provided by GET for Cloud Native Hybrid environments. **ALL Omnibus GET users with monitoring enabled are urged to consult the docs section on [Deprecated Omnibus-bundled Grafana](#deprecated-omnibus-bundled-grafana) for further information and next steps.**

While the implementation differs between Omnibus and Cloud Native Hybrid environments the same core components are used in each:

- [Prometheus](https://prometheus.io/) - For metrics collection and storage.
- [Grafana](https://grafana.com/) - To visualise the metrics.
- [Consul](https://www.consul.io/) - Component auto-discovery.

The Toolkit will configure these in each case, including scrape config, dashboard(s).

On this page we'll detail how to deploy the monitoring setup for each environment type with the Toolkit. Head to the relevant section below depending on the type of environment you have. **It's also worth noting this guide assumes a working knowledge of Prometheus, Grafana and Consul as well as being supplementary to the rest of the docs.**

[[_TOC_]]

## Omnibus

:information_source:&nbsp; As of GitLab 16.0, [Omnibus-bundled Grafana is deprecated](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#deprecation-of-bundled-grafana), and scheduled for removal from Omnibus in 16.3. **ALL Omnibus GET users with monitoring enabled are urged to consult the docs section on [Deprecated Omnibus-bundled Grafana](#deprecated-omnibus-bundled-grafana) for further information and next steps.**

In Omnibus environments the monitoring stack is provided by [Omnibus GitLab](https://docs.gitlab.com/omnibus/), which has Prometheus, Grafana and Consul built in.

In this setup, these components are deployed to their own VM named `monitor`. Like other Omnibus components this is enabled by simply deploying this node in Terraform and Ansible will configure it automatically. See the below sections for details on each.

**Terraform**

Provisioning the `monitor` node in Terraform that hosts the monitoring stack is the same as [deploying any other VM](environment_provision.md#configure-module-settings-environmenttf), for example:

```tf
module "gitlab_ref_arch_gcp" {
  source = "../../modules/gitlab_ref_arch_gcp"

  [...]

  monitor_node_count = 1
  monitor_machine_type = "n1-highcpu-4"
```

**Ansible**

With that node provisioned, Ansible will detect it, and configure the monitoring stack automatically. It will configure the relevant metrics exporters on the component nodes, and connect them to the Prometheus instance. It will also deploy select Grafana Dashboard(s).

By default, as given by Omnibus, Grafana will be configured with no authentication option. [Various options are available on how to configure authentication for Grafana](https://docs.gitlab.com/omnibus/settings/grafana.html#authentication) which can be configured with [Custom Config](environment_advanced.md#custom-config), but the Toolkit also allows for basic authentication of an Admin user and password via the following setting in your Ansible [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `grafana_password` - Password for the Grafana Admin user. Will also configure the basic authentication method.
  - Note that changing this password after it has been set will have no effect. The password needs to be changed directly [as detailed here](https://docs.gitlab.com/omnibus/settings/grafana.html#resetting-the-admin-password).
- `monitor_prometheus_scrape_config_setup` - Configures if any scrape configs should be configured by the Toolkit. Setting this to `false` will remove these to allow for more flexibility if desired. Optional, defaults to `true`.

Once completed, Grafana will be available at the address `<ENVIRONMENT_URL>/-/grafana`.

### Deprecated Omnibus-bundled Grafana

As of GitLab 16.0, [Omnibus-bundled Grafana has been deprecated](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#deprecation-of-bundled-grafana), and it is scheduled for removal from Omnibus in 16.3.

To prevent the unexpected removal of Grafana instances for existing users with monitoring enabled, GET currently enables the [temporary workaround in Omnibus](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#temporary-workaround) by default, but new users are encouraged to disable it as detailed below. This workaround will only be available for GitLab version 16.2 and earlier.

All users are urged to find [an alternative option to Omnibus-bundled Grafana](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#switch-to-new-grafana-instance), and can investigate [custom tasks in GET](environment_advanced.md#custom-tasks) as a means of installing an alternate visualization solution.

Disabling the bundled Grafana will not affect Prometheus or Consul. If the monitoring role is enabled, metrics will still be collected, but will not have a visualization solution unless an alternate is provided.

To disable Omnibus-bundled Grafana, include the following in your Ansible [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

```yml
monitor_enable_deprecated_grafana: false
```

Then run `ansible-playbook` with the intended environment's inventory against the `monitor.yml` and `haproxy.yml` playbooks.

```yml
ansible-playbook -i environments/<ENV_NAME>/inventory playbooks/monitor.yml
ansible-playbook -i environments/<ENV_NAME>/inventory playbooks/haproxy.yml
```

## Cloud Native Hybrid (`kube-prometheus-stack`)

In Cloud Native Hybrid environments the Toolkit utilises the [`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) and [`consul`](https://artifacthub.io/packages/helm/hashicorp/consul) Helm Charts to provide monitoring.

In this setup the two charts are deployed alongside GitLab in the same Kubernetes cluster. `kube-prometheus-stack` configures Prometheus via the Prometheus Operator to scrape various Kubernetes, Pod and GitLab metrics via [`ServiceMonitors`](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md#related-resources) as well as Grafana. Consul is also deployed and hooked up to the Omnibus Consul cluster to provide automated discovery for the Omnibus backends.

All of this is handled in Ansible via several settings in the [`vars.yml`](environment_configure.md#environment-config-varsyml) file:

- `cloud_native_hybrid_monitoring_setup` - Enables the setup of the monitoring stack. Defaults to `false`.
- `grafana_password` - Password for the Grafana Admin user.
- `kube_prometheus_stack_charts_namespace` - The [Kubernetes Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) for the `kube-prometheus-stack` chart. Defaults to `monitoring`.
- `kube_prometheus_stack_charts_storage_size` - The size of the [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) for Prometheus data storage. Must be given in the [SI or Binary notation](https://kubernetes.io/docs/reference/glossary/?all=true#term-quantity), for example a `100 GB` storage would be `100Gi`. Defaults to `100Gi`.
- `kube_prometheus_stack_charts_storage_class` - The [Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/) of the [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/). If left unset will use the provider's default (recommended). Defaults to `''`,
- `kube_prometheus_stack_charts_app_version` - The application version of the `kube-prometheus-stack` chart to deploy. Defaults to `v0.63.0`.
  - :information_source:&nbsp; Upgrades of the `kube-prometheus-stack` have [several moving parts](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack#upgrading-an-existing-release-to-a-new-major-version). The Toolkit pins the version it uses for this reason and regular tested updates of the version will be made in subsequent Toolkit releases. If desired, this version can be changed to perform an upgrade and the Toolkit will attempt to manage this in full, but your experience may be different.
- `kube_prometheus_stack_charts_prometheus_scrape_config_setup` - Configures if any scrape configs should be configured by the Toolkit. Setting this to `false` will remove these to allow for more flexibility if desired. Optional, defaults to `true`.
- `consul_charts_namespace` - The [Kubernetes Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) for the `consul` chart. Defaults to `consul`.
- `consul_charts_app_version` - The application version of the `consul` chart to deploy. Typically, should not be changed to ensure compatibility with Omnibus Consul version. Defaults to `1.12.3`.

For most deployments the default settings above should suffice. As such all that's required would be to enable the `cloud_native_hybrid_monitoring_setup` setting in your [`vars.yml`](environment_configure.md#environment-config-varsyml) file, for example:

```yml
all:
  vars:
    [...]

    cloud_native_hybrid_environment: true
    cloud_native_hybrid_monitoring_setup: true
```

Once completed, Grafana will be available at the address `<ENVIRONMENT_URL>/-/grafana`.

## Custom Config

Like [other areas](environment_advanced.md#custom-config) you can pass in Custom Config for the monitoring stacks also.

:exclamation:&nbsp; **This is an advanced feature, and it must be used with caution**. Any custom config passed will always take precedence and may lead to various unintended consequences or broken environments if not used carefully. This includes when setting [Scrape Config](#custom-prometheus-scrape-options) or [Rules](#custom-prometheus-rules) as detailed in later in this guide - Custom Config will always take precedence.

How this works differs depending on the environment setup used as detailed in the below sections.

### Omnibus

As Prometheus and Grafana are packaged within Omnibus [the standard approach detailed here](environment_advanced.md#omnibus) for the `monitor` node can be followed for any [valid config](https://docs.gitlab.com/ee/administration/monitoring/prometheus/).

### Cloud Native Hybrid (`kube-prometheus-stack`)

Setting Custom Config for the [`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) works as follows:

1. Create a [`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) yaml template file in the correct format with the specific custom settings you wish to apply
1. By default, the Toolkit looks for a [Jinja2 template file](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) named `kube_prometheus_stack_charts.yml.j2` in the [environment's](environment_configure.md#2-set-up-the-environments-inventory-and-config) `files/gitlab_configs` folder path. E.G. `ansible/environments/<env_name>/files/gitlab_configs/kube_prometheus_stack_charts.yml.j2`. Save your file in this location with the same name.
    - Files should be saved in Ansible template format - `.j2`.
    - If you wish to store your file in a different location or use a different name the full path that Ansible should use can be set via the `kube_prometheus_stack_charts_custom_config_file` inventory variable.

With the above done the file will be picked up by the Toolkit and used when configuring the chart.

## Custom Prometheus scrape options

When deploying either of the above stacks there are various options available on how Prometheus can be configured to scrape its targets.

By default, the Toolkit has the following options depending on the setup:

- Consul auto-discovery - When Consul is deployed it will be utilised to provide auto-discovery for Prometheus. This is recommended in most cases as it can handle situations such as IPs changing.
- Static internal IPs - When Consul is not deployed, static internal IPs will be used instead.
- None - As an additional option the Toolkit can also add no scrape configs for flexibility as desired via the Ansible `monitor_prometheus_scrape_config_setup` / `kube_prometheus_stack_charts_prometheus_scrape_config_setup` variables.
- Custom - Additive to any of the above options, you can also pass in your own custom scrape configs as desired.

How this works for each environment type differs as detailed in the below sections.

:information_source:&nbsp; Note that [Custom Config](#custom-config) will take precedence over this if the same underlying variables are specified.

### Omnibus

For Omnibus, [scrape configs are passed in a JSON dictionary format](https://docs.gitlab.com/ee/administration/monitoring/prometheus/#adding-custom-scrape-configurations). This is done via the following variable:

- `monitor_custom_prometheus_scrape_config` - A list of custom scrape configs to configure in JSON dictionary format.

An example of how you would configure this, in this case for an Influx DB [with exporter enabled](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#static_config), in the Ansible [`vars.yml`](environment_configure.md#environment-config-varsyml) file would be as follows:

```yml
monitor_custom_prometheus_scrape_config: |
  {
    'job_name': 'influxdb',
    'static_configs' => [
      'targets' => ["<INFLUXDB_URL>:9122"],
    ],
  },
```

### Cloud Native Hybrid (`kube-prometheus-stack`)

For Cloud Native Hybrid, [scrape configs are passed in a YAML dictionary format](https://prometheus.io/docs/prometheus/latest/configuration/configuration). This is done via the following variable:

- `kube_prometheus_stack_charts_custom_scrape_config` - A list of custom scrape configs to configure in YAML dictionary format.

An example of how you would configure this, in this case for an Influx DB [with exporter enabled](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#static_config), in the Ansible [`vars.yml`](environment_configure.md#environment-config-varsyml) file would be as follows:

```yml
kube_prometheus_stack_charts_custom_scrape_config:
  - job_name: influxdb
    static_configs:
      - targets:
        - "<INFLUXDB_URL>:9122"
```

## Custom Prometheus rules

The Toolkit allows for you to pass in custom alert/record rules to be used in Prometheus for either the Omnibus or Cloud Native Hybrid setups described above.

By default, the Toolkit will look for rules under the `environments/<env_name>/files/prometheus` folder. In Prometheus, rules are typically organised under group folders, so the same is expected here. As such, rules should be placed in their own group folder in this path, for example `environments/<env_name>/files/prometheus/<rules group folder name>/<rule files>`. You can create multiple folders to store different rule groups or store everything in a single folder. You can also store the rules in a different location other than `environments/<env_name>/files/prometheus/` for each setup.

Once the rules are in place you can then configure the Toolkit to set these up accordingly. This is done by configuring the Toolkit to know what sub-folders of rules to transfer over.

For details on how to do this for each setup, refer to the applicable section below.

:information_source:&nbsp; Note that [Custom Config](#custom-config) will take precedence over this if the same underlying variables are specified.

### Omnibus

For Omnibus, the following variables are used to configure custom rules:

- `monitor_custom_rules_path` - Path the Toolkit will look under for any rules. Default is `environments/<env_name>/files/prometheus`.
- `monitor_custom_rules` - List of rule folders under `monitor_custom_rules_path` the Toolkit should transfer. Each entry requires a couple of variables to be set in dict format: For each a dict should be set with the following sub-variables:
  - `folder` - The folder under `monitor_custom_rules_path` to transfer over
  
An example of how you would configure this for several folders in the default location would be as follows:

```yaml
monitor_custom_rules:
  - folder: 'my_sidekiq_rules'
  - folder: 'my_gitaly_rules'
```

## Custom Grafana Dashboards

The Toolkit allows you to pass in custom dashboards to be used in Grafana for either the Omnibus or Cloud Native Hybrid setups described above.

By default, the Toolkit will look for Dashboards under the `environments/<env_name>/files/grafana` folder. In Grafana, Dashboards are typically organised under folders, so the same is expected here. As such, Dashboards should be placed in their own folder in this path, for example `environments/<env_name>/files/grafana/<dashboards folder name>/<dashboard files>`. You can create multiple folders to store different dashboards or store everything in a single folder. You can also store the dashboards in a different location other than `environments/<env_name>/files/grafana/` for each setup.

Once the dashboards are in place you can then configure the Toolkit to set these up accordingly. This is done by configuring the Toolkit to know what sub-folders of dashboards to transfer over as well as configuring how they are displayed in the Grafana UI.

For details on how to do this for each setup, refer to the applicable section below.

:information_source:&nbsp; Note that [Custom Config](#custom-config) will take precedence over this if the same underlying variables are specified.

### Omnibus

For Omnibus, the following variables are used to configure custom dashboards:

- `monitor_custom_dashboards_path` - Path the Toolkit will look under for any Dashboards. Default is `environments/<env_name>/files/grafana`.
- `monitor_custom_dashboards` - List of Dashboard folders under `monitor_custom_dashboards_path` the Toolkit should transfer. Each entry requires a couple of variables to be set in dict format: For each a dict should be set with the following sub-variables:
  - `folder` - The folder under `monitor_custom_dashboards_path` to transfer over
  - `display_name` - Display name of Folder to be shown in the Grafana UI.

An example of how you would configure this for several folders in the default location would be as follows:

```yaml
monitor_custom_dashboards:
  - folder: 'my_sidekiq_dashboards'
    display_name: 'Sidekiq Dashboards'
  - folder: 'my_gitaly_dashboards'
    display_name: 'Gitaly Dashboards'
```

### Cloud Native Hybrid (`kube-prometheus-stack`)

For Cloud Native Hybrid, the following variables are used to configure custom dashboards:

- `kube_prometheus_stack_charts_custom_dashboards_path` - Path the Toolkit will look under for any Dashboards. Default is `environments/<env_name>/files/grafana`.
- `kube_prometheus_stack_charts_custom_dashboards` - List of Dashboard folders under `kube_prometheus_stack_charts_custom_dashboards_path` the Toolkit should transfer. Each entry requires a couple of variables to be set in dict format: For each a dict should be set with the following sub-variables:
  - `folder` - The folder under `kube_prometheus_stack_charts_custom_dashboards_path` to transfer over
  - `display_name` - Display name of Folder to be shown in the Grafana UI.

An example of how you would configure this for several folders in the default location would be as follows:

```yaml
kube_prometheus_stack_charts_custom_dashboards:
  - folder: 'my_sidekiq_dashboards'
    display_name: 'Sidekiq Dashboards'
  - folder: 'my_gitaly_dashboards'
    display_name: 'Gitaly Dashboards'
```
