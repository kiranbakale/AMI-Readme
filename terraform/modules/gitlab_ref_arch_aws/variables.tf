# General
variable "prefix" { default = null }
variable "geo_site" { default = null }
variable "geo_deployment" { default = null }

# AWS Settings
variable "ami_id" { default = null } # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami

variable "default_disk_size" { default = "100" }
variable "default_disk_type" { default = "gp2" }

variable "ssh_key" { default = null }

variable "object_storage_buckets" { default = ["artifacts", "backups", "dependency-proxy", "lfs", "mr-diffs", "packages", "terraform-state", "uploads"] }

# Machines
variable "consul_node_count" { default = 0 }
variable "consul_instance_type" { default = "" }
variable "consul_disk_type" { default = null }
variable "consul_disk_size" { default = null }

variable "elastic_node_count" { default = 0 }
variable "elastic_instance_type" { default = "" }
variable "elastic_disk_type" { default = null }
variable "elastic_disk_size" { default = "500" }

variable "gitaly_node_count" { default = 0 }
variable "gitaly_instance_type" { default = "" }
variable "gitaly_disk_type" { default = null }
variable "gitaly_disk_size" { default = "500" }

variable "gitlab_nfs_node_count" { default = 0 }
variable "gitlab_nfs_instance_type" { default = "" }
variable "gitlab_nfs_disk_type" { default = null }
variable "gitlab_nfs_disk_size" { default = null }

variable "gitlab_rails_node_count" { default = 0 }
variable "gitlab_rails_instance_type" { default = "" }
variable "gitlab_rails_disk_type" { default = null }
variable "gitlab_rails_disk_size" { default = null }

variable "haproxy_external_node_count" { default = 0 }
variable "haproxy_external_instance_type" { default = "" }
variable "haproxy_external_disk_type" { default = null }
variable "haproxy_external_disk_size" { default = null }
variable "haproxy_external_elastic_ip_allocation_ids" { default = [] }

variable "haproxy_internal_node_count" { default = 0 }
variable "haproxy_internal_instance_type" { default = "" }
variable "haproxy_internal_disk_type" { default = null }
variable "haproxy_internal_disk_size" { default = null }

variable "monitor_node_count" { default = 0 }
variable "monitor_instance_type" { default = "" }
variable "monitor_disk_type" { default = null }
variable "monitor_disk_size" { default = null }

variable "pgbouncer_node_count" { default = 0 }
variable "pgbouncer_instance_type" { default = "" }
variable "pgbouncer_disk_type" { default = null }
variable "pgbouncer_disk_size" { default = null }

variable "postgres_node_count" { default = 0 }
variable "postgres_instance_type" { default = "" }
variable "postgres_disk_type" { default = null }
variable "postgres_disk_size" { default = null }

variable "praefect_node_count" { default = 0 }
variable "praefect_instance_type" { default = "" }
variable "praefect_disk_type" { default = null }
variable "praefect_disk_size" { default = null }

variable "praefect_postgres_node_count" { default = 0 }
variable "praefect_postgres_instance_type" { default = "" }
variable "praefect_postgres_disk_type" { default = null }
variable "praefect_postgres_disk_size" { default = null }

variable "redis_node_count" { default = 0 }
variable "redis_instance_type" { default = "" }
variable "redis_disk_type" { default = null }
variable "redis_disk_size" { default = null }

variable "redis_cache_node_count" { default = 0 }
variable "redis_cache_instance_type" { default = "" }
variable "redis_cache_disk_type" { default = null }
variable "redis_cache_disk_size" { default = null }

variable "redis_persistent_node_count" { default = 0 }
variable "redis_persistent_instance_type" { default = "" }
variable "redis_persistent_disk_type" { default = null }
variable "redis_persistent_disk_size" { default = null }

variable "redis_sentinel_cache_node_count" { default = 0 }
variable "redis_sentinel_cache_instance_type" { default = "" }
variable "redis_sentinel_cache_disk_type" { default = null }
variable "redis_sentinel_cache_disk_size" { default = null }

variable "redis_sentinel_persistent_node_count" { default = 0 }
variable "redis_sentinel_persistent_instance_type" { default = "" }
variable "redis_sentinel_persistent_disk_type" { default = null }
variable "redis_sentinel_persistent_disk_size" { default = null }

variable "sidekiq_node_count" { default = 0 }
variable "sidekiq_instance_type" { default = "" }
variable "sidekiq_disk_type" { default = null }
variable "sidekiq_disk_size" { default = null }
