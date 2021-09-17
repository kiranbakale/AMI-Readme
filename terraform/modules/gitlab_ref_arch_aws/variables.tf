# General
variable "prefix" {
  default     = null
  type        = string
  description = "Prefix to use on all provisioned resources"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,29}$", var.prefix))
    error_message = "The prefix must be all lowercase alphanumeric characters, between 3 and 30 characters in length."
  }
}

variable "geo_site" { default = null }
variable "geo_deployment" { default = null }

# AWS Settings
variable "ami_id" { default = null } # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami

variable "default_disk_size" { default = "100" }
variable "default_disk_type" { default = "gp3" }

variable "ssh_public_key_file" { default = null }

variable "object_storage_buckets" { default = ["artifacts", "backups", "dependency-proxy", "lfs", "mr-diffs", "packages", "terraform-state", "uploads", "registry"] }
variable "object_storage_force_destroy" {
  description = "Toggle to enable force-destruction of S3 Bucket. Consider setting this value to false for production systems"
  type        = bool
  default     = true
}
variable "object_storage_tags" {
  description = "Tags to apply to S3 buckets"
  type        = map(any)
  default     = {}
}

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

# Separate Redis Sentinel is Deprecated - To be removed in future release
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

# Kubernetes \ Helm
variable "webservice_node_pool_count" { default = 0 }
variable "webservice_node_pool_instance_type" { default = "" }
variable "webservice_node_pool_disk_size" { default = "100" }

variable "sidekiq_node_pool_count" { default = 0 }
variable "sidekiq_node_pool_instance_type" { default = "" }
variable "sidekiq_node_pool_disk_size" { default = "100" }

variable "supporting_node_pool_count" { default = 0 }
variable "supporting_node_pool_instance_type" { default = "" }
variable "supporting_node_pool_disk_size" { default = null }

# AWS Kubernetes Auth Map
variable "aws_auth_roles" {
  type = list(object({
    rolearn       = string       # The IAM role ARN for the role that requires access
    kube_username = string       # The username of the kubernetes user for the Role
    kube_groups   = list(string) # The kubernetes groups that the user belongs to
  }))
  default = []
}

# PaaS Services
## PostgreSQL
variable "rds_postgres_instance_type" { default = "" }
variable "rds_postgres_port" { default = 5432 }
variable "rds_postgres_username" { default = "gitlab" }
variable "rds_postgres_password" { default = "" }
variable "rds_postgres_database_name" { default = "gitlabhq_production" }
variable "rds_postgres_version" { default = "12.6" }
variable "rds_postgres_allocated_storage" { default = 100 }
variable "rds_postgres_max_allocated_storage" { default = 1000 }
variable "rds_postgres_multi_az" { default = true }
variable "rds_postgres_iops" { default = 1000 }
variable "rds_postgres_storage_type" { default = "io1" }
variable "rds_postgres_kms_key_arn" { default = null }

## Redis
### Combined
variable "elasticache_redis_node_count" { default = 0 }
variable "elasticache_redis_instance_type" { default = "" }
variable "elasticache_redis_kms_key_arn" { default = null }

variable "elasticache_redis_engine_version" { default = "6.x" }
variable "elasticache_redis_password" { default = "" }
variable "elasticache_redis_port" { default = 6379 }
variable "elasticache_redis_multi_az" { default = true }

### Separate - Cache
variable "elasticache_redis_cache_node_count" { default = 0 }
variable "elasticache_redis_cache_instance_type" { default = "" }
variable "elasticache_redis_cache_kms_key_arn" { default = null }

variable "elasticache_redis_cache_engine_version" { default = null }
variable "elasticache_redis_cache_password" { default = "" }
variable "elasticache_redis_cache_port" { default = null }
variable "elasticache_redis_cache_multi_az" { default = null }

### Separate - Persistent
variable "elasticache_redis_persistent_node_count" { default = 0 }
variable "elasticache_redis_persistent_instance_type" { default = "" }
variable "elasticache_redis_persistent_kms_key_arn" { default = null }

variable "elasticache_redis_persistent_engine_version" { default = null }
variable "elasticache_redis_persistent_password" { default = "" }
variable "elasticache_redis_persistent_port" { default = null }
variable "elasticache_redis_persistent_multi_az" { default = null }

# Networking
## Create new network
variable "create_network" { default = false }
variable "vpc_cidr_block" { default = "172.31.0.0/16" }
variable "subpub_pub_cidr_block" { default = ["172.31.0.0/20", "172.31.16.0/20", "172.31.32.0/20"] }
variable "subnet_pub_count" { default = 2 }

## Existing network
variable "vpc_id" { default = null }
variable "subnet_ids" { default = null }

## Default Network
variable "default_subnet_use_count" { default = 2 }
