# General
variable "prefix" { default = null }
variable "geo_site" { default = null }
variable "geo_deployment" { default = null }

# Azure
variable "source_image_reference" {
  type = map
  default = {
    "publisher"  = "Canonical"
    "offer"  = "UbuntuServer"
    "sku"  = "18.04-LTS"
    "version"  = "latest"
  }
}

variable "location" {  default = "East US 2" }
variable "storage_account_name" { default = null }
variable "resource_group_name" { default = null }
variable "vm_admin_username" { default = null }
variable "ssh_public_key_file_path" { default = null }

variable "default_disk_size" { default = "100" }
variable "default_storage_account_type" { default = "Standard_LRS" }

variable "object_storage_buckets" { default = ["artifacts", "backups", "dependency-proxy", "lfs", "mr-diffs", "packages", "terraform-state", "uploads"] }

variable "project" { default = null }

# Machines
variable "consul_node_count" { default = 0 }
variable "consul_size" { default = "" }
variable "consul_storage_account_type" { default = null }
variable "consul_disk_size" { default = null }

variable "elastic_node_count" { default = 0 }
variable "elastic_size" { default = "" }
variable "elastic_storage_account_type" { default = "Premium_LRS" }
variable "elastic_disk_size" { default = "4095" }

variable "gitaly_node_count" { default = 0 }
variable "gitaly_size" { default = "" }
variable "gitaly_storage_account_type" { default = "Premium_LRS" }
variable "gitaly_disk_size" { default = "4095" }

variable "gitlab_nfs_node_count" { default = 0 }
variable "gitlab_nfs_size" { default = "" }
variable "gitlab_nfs_storage_account_type" { default = null }
variable "gitlab_nfs_disk_size" { default = null }

variable "gitlab_rails_node_count" { default = 0 }
variable "gitlab_rails_size" { default = "" }
variable "gitlab_rails_storage_account_type" { default = null }
variable "gitlab_rails_disk_size" { default = null }

variable "haproxy_external_node_count" { default = 0 }
variable "haproxy_external_size" { default = "" }
variable "haproxy_external_storage_account_type" { default = null }
variable "haproxy_external_disk_size" { default = null }
variable "haproxy_external_external_ip_names" { default = [] }

variable "haproxy_internal_node_count" { default = 0 }
variable "haproxy_internal_size" { default = "" }
variable "haproxy_internal_storage_account_type" { default = null }
variable "haproxy_internal_disk_size" { default = null }

variable "monitor_node_count" { default = 0 }
variable "monitor_size" { default = "" }
variable "monitor_storage_account_type" { default = null }
variable "monitor_disk_size" { default = null }

variable "pgbouncer_node_count" { default = 0 }
variable "pgbouncer_size" { default = "" }
variable "pgbouncer_storage_account_type" { default = null }
variable "pgbouncer_disk_size" { default = null }

variable "postgres_node_count" { default = 0 }
variable "postgres_size" { default = "" }
variable "postgres_storage_account_type" { default = null }
variable "postgres_disk_size" { default = null }

variable "praefect_node_count" { default = 0 }
variable "praefect_size" { default = "" }
variable "praefect_storage_account_type" { default = null }
variable "praefect_disk_size" { default = null }

variable "praefect_postgres_node_count" { default = 0 }
variable "praefect_postgres_size" { default = "" }
variable "praefect_postgres_storage_account_type" { default = null }
variable "praefect_postgres_disk_size" { default = null }

variable "redis_node_count" { default = 0 }
variable "redis_size" { default = "" }
variable "redis_storage_account_type" { default = null }
variable "redis_disk_size" { default = null }

variable "redis_cache_node_count" { default = 0 }
variable "redis_cache_size" { default = "" }
variable "redis_cache_storage_account_type" { default = null }
variable "redis_cache_disk_size" { default = null }

variable "redis_persistent_node_count" { default = 0 }
variable "redis_persistent_size" { default = "" }
variable "redis_persistent_storage_account_type" { default = null }
variable "redis_persistent_disk_size" { default = null }

# Separate Redis Sentinel is Deprecated - To be removed in future release
variable "redis_sentinel_cache_node_count" { default = 0 }
variable "redis_sentinel_cache_size" { default = "" }
variable "redis_sentinel_cache_storage_account_type" { default = null }
variable "redis_sentinel_cache_disk_size" { default = null }

variable "redis_sentinel_persistent_node_count" { default = 0 }
variable "redis_sentinel_persistent_size" { default = "" }
variable "redis_sentinel_persistent_storage_account_type" { default = null }
variable "redis_sentinel_persistent_disk_size" { default = null }

variable "sidekiq_node_count" { default = 0 }
variable "sidekiq_size" { default = "" }
variable "sidekiq_storage_account_type" { default = null }
variable "sidekiq_disk_size" { default = null }
