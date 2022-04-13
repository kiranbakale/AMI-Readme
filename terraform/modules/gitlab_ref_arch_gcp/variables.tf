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

# Object Storage
variable "object_storage_buckets" {
  type    = list(string)
  default = ["artifacts", "backups", "dependency-proxy", "lfs", "mr-diffs", "packages", "terraform-state", "uploads"]
}
variable "object_storage_prefix" {
  type    = string
  default = null
}
variable "object_storage_location" {
  type    = string
  default = "US"
}
variable "object_storage_force_destroy" {
  description = "Toggle to enable force-destruction of object storage buckets. Consider setting this value to false for production systems"
  type        = bool
  default     = true
}
variable "object_storage_labels" {
  description = "Labels to apply to object storage buckets"
  type        = map(string)
  default     = {}
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
## Cluster Autoscaling (Optional)
variable "webservice_node_pool_max_count" {
  type    = number
  default = 0
}
variable "webservice_node_pool_min_count" {
  type    = number
  default = 0
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
## Cluster Autoscaling (Optional)
variable "sidekiq_node_pool_max_count" {
  type    = number
  default = 0
}
variable "sidekiq_node_pool_min_count" {
  type    = number
  default = 0
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
## Cluster Autoscaling (Optional)
variable "supporting_node_pool_max_count" {
  type    = number
  default = 0
}
variable "supporting_node_pool_min_count" {
  type    = number
  default = 0
}

variable "cluster_release_channel" {
  type    = string
  default = "STABLE"
}
variable "cluster_enable_workload_identity" {
  type    = bool
  default = false
}

# Networking
## Create new network
variable "create_network" {
  type    = bool
  default = false
}

## Default network
variable "default_allowed_ingress_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "http_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

variable "ssh_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

variable "external_ssh_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

variable "icmp_allowed_ingress_cidr_blocks" {
  type    = list(any)
  default = []
}

## Existing network
variable "vpc_name" {
  type    = string
  default = "default"
}
variable "subnet_name" {
  type    = string
  default = "default"
}
variable "subnet_cidr" {
  type    = string
  default = "10.86.0.0/16"
}

## External IPs
variable "setup_external_ips" {
  type    = bool
  default = true
}

## Zones
variable "zones" {
  type    = list(any)
  default = null
}
variable "kubernetes_zones" {
  type    = list(any)
  default = null
}

## Labels
variable "additional_labels" {
  type    = map(any)
  default = {}
}

# Additional
variable "allow_stopping_for_update" {
  type    = bool
  default = true
}
variable "machine_secure_boot" {
  type    = bool
  default = false
}
