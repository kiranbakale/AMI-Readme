# General
variable "prefix" {
  type    = string
  default = null
}
variable "geo_site" {
  type    = string
  default = null
}
variable "geo_deployment" {
  type    = string
  default = null
}

# GCP Settings
variable "machine_image" {
  type    = string
  default = "ubuntu-1804-lts"
}

variable "default_disk_size" {
  type    = string
  default = "100"
}
variable "default_disk_type" {
  type    = string
  default = "pd-standard"
}

variable "project" {
  type    = string
  default = null
}

variable "object_storage_buckets" {
  type    = list(string)
  default = ["artifacts", "backups", "dependency-proxy", "lfs", "mr-diffs", "packages", "terraform-state", "uploads"]
}

# A NAT will be created if setup_external_ips is set to false
variable "setup_external_ips" {
  type    = bool
  default = true
}
# Set use_existing_nat=true to use a NAT outside of GET
variable "use_existing_nat" {
  type    = bool
  default = false
}

# Machines
variable "consul_node_count" {
  type    = number
  default = 0
}
variable "consul_machine_type" {
  type    = string
  default = ""
}
variable "consul_disk_type" {
  type    = string
  default = null
}
variable "consul_disk_size" {
  type    = string
  default = null
}
variable "consul_disks" {
  type    = list(any)
  default = []
}

variable "elastic_node_count" {
  type    = number
  default = 0
}
variable "elastic_machine_type" {
  type    = string
  default = ""
}
variable "elastic_disk_type" {
  type    = string
  default = "pd-ssd"
}
variable "elastic_disk_size" {
  type    = string
  default = "500"
}
variable "elastic_disks" {
  type    = list(any)
  default = []
}

variable "gitaly_node_count" {
  type    = number
  default = 0
}
variable "gitaly_machine_type" {
  type    = string
  default = ""
}
variable "gitaly_disk_type" {
  type    = string
  default = "pd-ssd"
}
variable "gitaly_disk_size" {
  type    = string
  default = "500"
}
variable "gitaly_disks" {
  type    = list(any)
  default = []
}

variable "gitlab_nfs_node_count" {
  type    = number
  default = 0
}
variable "gitlab_nfs_machine_type" {
  type    = string
  default = ""
}
variable "gitlab_nfs_disk_type" {
  type    = string
  default = null
}
variable "gitlab_nfs_disk_size" {
  type    = string
  default = null
}
variable "gitlab_nfs_disks" {
  type    = list(any)
  default = []
}

variable "gitlab_rails_node_count" {
  type    = number
  default = 0
}
variable "gitlab_rails_machine_type" {
  type    = string
  default = ""
}
variable "gitlab_rails_disk_type" {
  type    = string
  default = null
}
variable "gitlab_rails_disk_size" {
  type    = string
  default = null
}
variable "gitlab_rails_disks" {
  type    = list(any)
  default = []
}

variable "haproxy_external_node_count" {
  type    = number
  default = 0
}
variable "haproxy_external_machine_type" {
  type    = string
  default = ""
}
variable "haproxy_external_disk_type" {
  type    = string
  default = null
}
variable "haproxy_external_disk_size" {
  type    = string
  default = null
}
variable "haproxy_external_external_ips" {
  type    = list(string)
  default = []
}
variable "haproxy_external_disks" {
  type    = list(any)
  default = []
}

variable "haproxy_internal_node_count" {
  type    = number
  default = 0
}
variable "haproxy_internal_machine_type" {
  type    = string
  default = ""
}
variable "haproxy_internal_disk_type" {
  type    = string
  default = null
}
variable "haproxy_internal_disk_size" {
  type    = string
  default = null
}
variable "haproxy_internal_disks" {
  type    = list(any)
  default = []
}

variable "monitor_node_count" {
  type    = number
  default = 0
}
variable "monitor_machine_type" {
  type    = string
  default = ""
}
variable "monitor_disk_type" {
  type    = string
  default = null
}
variable "monitor_disk_size" {
  type    = string
  default = null
}
variable "monitor_disks" {
  type    = list(any)
  default = []
}

variable "pgbouncer_node_count" {
  type    = number
  default = 0
}
variable "pgbouncer_machine_type" {
  type    = string
  default = ""
}
variable "pgbouncer_disk_type" {
  type    = string
  default = null
}
variable "pgbouncer_disk_size" {
  type    = string
  default = null
}
variable "pgbouncer_disks" {
  type    = list(any)
  default = []
}

variable "postgres_node_count" {
  type    = number
  default = 0
}
variable "postgres_machine_type" {
  type    = string
  default = ""
}
variable "postgres_disk_type" {
  type    = string
  default = null
}
variable "postgres_disk_size" {
  type    = string
  default = null
}
variable "postgres_disks" {
  type    = list(any)
  default = []
}

variable "praefect_node_count" {
  type    = number
  default = 0
}
variable "praefect_machine_type" {
  type    = string
  default = ""
}
variable "praefect_disk_type" {
  type    = string
  default = null
}
variable "praefect_disk_size" {
  type    = string
  default = null
}
variable "praefect_disks" {
  type    = list(any)
  default = []
}

variable "praefect_postgres_node_count" {
  type    = number
  default = 0
}
variable "praefect_postgres_machine_type" {
  type    = string
  default = ""
}
variable "praefect_postgres_disk_type" {
  type    = string
  default = null
}
variable "praefect_postgres_disk_size" {
  type    = string
  default = null
}
variable "praefect_postgres_disks" {
  type    = list(any)
  default = []
}

variable "redis_node_count" {
  type    = number
  default = 0
}
variable "redis_machine_type" {
  type    = string
  default = ""
}
variable "redis_disk_type" {
  type    = string
  default = null
}
variable "redis_disk_size" {
  type    = string
  default = null
}
variable "redis_disks" {
  type    = list(any)
  default = []
}

variable "redis_cache_node_count" {
  type    = number
  default = 0
}
variable "redis_cache_machine_type" {
  type    = string
  default = ""
}
variable "redis_cache_disk_type" {
  type    = string
  default = null
}
variable "redis_cache_disk_size" {
  type    = string
  default = null
}
variable "redis_cache_disks" {
  type    = list(any)
  default = []
}

variable "redis_persistent_node_count" {
  type    = number
  default = 0
}
variable "redis_persistent_machine_type" {
  type    = string
  default = ""
}
variable "redis_persistent_disk_type" {
  type    = string
  default = null
}
variable "redis_persistent_disk_size" {
  type    = string
  default = null
}
variable "redis_persistent_disks" {
  type    = list(any)
  default = []
}

# Separate Redis Sentinel is Deprecated - To be removed in future release
variable "redis_sentinel_cache_node_count" {
  type    = number
  default = 0
}
variable "redis_sentinel_cache_machine_type" {
  type    = string
  default = ""
}
variable "redis_sentinel_cache_disk_type" {
  type    = string
  default = null
}
variable "redis_sentinel_cache_disk_size" {
  type    = string
  default = null
}
variable "redis_sentinel_cache_disks" {
  type    = list(any)
  default = []
}

variable "redis_sentinel_persistent_node_count" {
  type    = number
  default = 0
}
variable "redis_sentinel_persistent_machine_type" {
  type    = string
  default = ""
}
variable "redis_sentinel_persistent_disk_type" {
  type    = string
  default = null
}
variable "redis_sentinel_persistent_disk_size" {
  type    = string
  default = null
}
variable "redis_sentinel_persistent_disks" {
  type    = list(any)
  default = []
}

variable "sidekiq_node_count" {
  type    = number
  default = 0
}
variable "sidekiq_machine_type" {
  type    = string
  default = ""
}
variable "sidekiq_disk_type" {
  type    = string
  default = null
}
variable "sidekiq_disk_size" {
  type    = string
  default = null
}
variable "sidekiq_disks" {
  type    = list(any)
  default = []
}

# Kubernetes \ Helm

variable "webservice_node_pool_count" {
  type    = number
  default = 0
}
variable "webservice_node_pool_machine_type" {
  type    = string
  default = ""
}
variable "webservice_node_pool_disk_type" {
  type    = string
  default = null
}
variable "webservice_node_pool_disk_size" {
  type    = string
  default = null
}

variable "sidekiq_node_pool_count" {
  type    = number
  default = 0
}
variable "sidekiq_node_pool_machine_type" {
  type    = string
  default = ""
}
variable "sidekiq_node_pool_disk_type" {
  type    = string
  default = null
}
variable "sidekiq_node_pool_disk_size" {
  type    = string
  default = null
}

variable "supporting_node_pool_count" {
  type    = number
  default = 0
}
variable "supporting_node_pool_machine_type" {
  type    = string
  default = ""
}
variable "supporting_node_pool_disk_type" {
  type    = string
  default = null
}
variable "supporting_node_pool_disk_size" {
  type    = string
  default = null
}
