# General
variable "prefix" {
  description = "Prefix to use on all provisioned resources"
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,29}$", var.prefix))
    error_message = "The prefix must be all lowercase alphanumeric characters, between 3 and 30 characters in length."
  }
}

variable "geo_site" {
  type    = string
  default = null
}
variable "geo_deployment" {
  type    = string
  default = null
}

# AWS Settings

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
variable "ami_id" {
  type    = string
  default = null
}

variable "default_disk_size" {
  type    = string
  default = "100"
}

variable "default_disk_type" {
  type    = string
  default = "gp3"
}

variable "ssh_public_key_file" {
  type    = string
  default = null
}

variable "object_storage_buckets" {
  type    = list(string)
  default = ["artifacts", "backups", "dependency-proxy", "lfs", "mr-diffs", "packages", "terraform-state", "uploads", "registry"]
}
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
variable "consul_node_count" {
  type    = number
  default = 0
}
variable "consul_instance_type" {
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
variable "consul_data_disks" {
  type    = list(any)
  default = []
}

variable "elastic_node_count" {
  type    = number
  default = 0
}
variable "elastic_instance_type" {
  type    = string
  default = ""
}
variable "elastic_disk_type" {
  type    = string
  default = null
}
variable "elastic_disk_size" {
  type    = string
  default = "500"
}
variable "elastic_data_disks" {
  type    = list(any)
  default = []
}

variable "gitaly_node_count" {
  type    = number
  default = 0
}
variable "gitaly_instance_type" {
  type    = string
  default = ""
}
variable "gitaly_disk_type" {
  type    = string
  default = null
}
variable "gitaly_disk_size" {
  type    = string
  default = "500"
}
variable "gitaly_data_disks" {
  type    = list(any)
  default = []
}

variable "gitlab_nfs_node_count" {
  type    = number
  default = 0
}
variable "gitlab_nfs_instance_type" {
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
variable "gitlab_nfs_data_disks" {
  type    = list(any)
  default = []
}

variable "gitlab_rails_node_count" {
  type    = number
  default = 0
}
variable "gitlab_rails_instance_type" {
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
variable "gitlab_rails_data_disks" {
  type    = list(any)
  default = []
}

variable "haproxy_external_node_count" {
  type    = number
  default = 0
}
variable "haproxy_external_instance_type" {
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
variable "haproxy_external_elastic_ip_allocation_ids" {
  type    = list(string)
  default = []
}
variable "haproxy_external_data_disks" {
  type    = list(any)
  default = []
}

variable "haproxy_internal_node_count" {
  type    = number
  default = 0
}
variable "haproxy_internal_instance_type" {
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
variable "haproxy_internal_data_disks" {
  type    = list(any)
  default = []
}

variable "monitor_node_count" {
  type    = number
  default = 0
}
variable "monitor_instance_type" {
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
variable "monitor_data_disks" {
  type    = list(any)
  default = []
}

variable "pgbouncer_node_count" {
  type    = number
  default = 0
}
variable "pgbouncer_instance_type" {
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
variable "pgbouncer_data_disks" {
  type    = list(any)
  default = []
}

variable "postgres_node_count" {
  type    = number
  default = 0
}
variable "postgres_instance_type" {
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
variable "postgres_data_disks" {
  type    = list(any)
  default = []
}

variable "praefect_node_count" {
  type    = number
  default = 0
}
variable "praefect_instance_type" {
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
variable "praefect_data_disks" {
  type    = list(any)
  default = []
}

variable "praefect_postgres_node_count" {
  type    = number
  default = 0
}
variable "praefect_postgres_instance_type" {
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
variable "praefect_postgres_data_disks" {
  type    = list(any)
  default = []
}

variable "redis_node_count" {
  type    = number
  default = 0
}
variable "redis_instance_type" {
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
variable "redis_data_disks" {
  type    = list(any)
  default = []
}

variable "redis_cache_node_count" {
  type    = number
  default = 0
}
variable "redis_cache_instance_type" {
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
variable "redis_cache_data_disks" {
  type    = list(any)
  default = []
}

variable "redis_persistent_node_count" {
  type    = number
  default = 0
}
variable "redis_persistent_instance_type" {
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
variable "redis_persistent_data_disks" {
  type    = list(any)
  default = []
}


# Separate Redis Sentinel is Deprecated - To be removed in future release
variable "redis_sentinel_cache_node_count" {
  type    = number
  default = 0
}
variable "redis_sentinel_cache_instance_type" {
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

variable "redis_sentinel_persistent_node_count" {
  type    = number
  default = 0
}
variable "redis_sentinel_persistent_instance_type" {
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

variable "sidekiq_node_count" {
  type    = number
  default = 0
}
variable "sidekiq_instance_type" {
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
variable "sidekiq_data_disks" {
  type    = list(any)
  default = []
}


# Kubernetes \ Helm
variable "webservice_node_pool_count" {
  type    = number
  default = 0
}
variable "webservice_node_pool_instance_type" {
  type    = string
  default = ""
}
variable "webservice_node_pool_disk_size" {
  type    = string
  default = "100"
}

variable "sidekiq_node_pool_count" {
  type    = number
  default = 0
}
variable "sidekiq_node_pool_instance_type" {
  type    = string
  default = ""
}
variable "sidekiq_node_pool_disk_size" {
  type    = string
  default = "100"
}

variable "supporting_node_pool_count" {
  type    = number
  default = 0
}
variable "supporting_node_pool_instance_type" {
  type    = string
  default = ""
}
variable "supporting_node_pool_disk_size" {
  type    = string
  default = null
}

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
variable "rds_postgres_instance_type" {
  type    = string
  default = ""
}
variable "rds_postgres_port" {
  type    = number
  default = 5432
}
variable "rds_postgres_username" {
  type    = string
  default = "gitlab"
}
variable "rds_postgres_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "rds_postgres_database_name" {
  type    = string
  default = "gitlabhq_production"
}
variable "rds_postgres_version" {
  type    = string
  default = "12.6"
}
variable "rds_postgres_allocated_storage" {
  type    = number
  default = 100
}
variable "rds_postgres_max_allocated_storage" {
  type    = number
  default = 1000
}
variable "rds_postgres_multi_az" {
  type    = bool
  default = true
}
variable "rds_postgres_iops" {
  type    = number
  default = 1000
}
variable "rds_postgres_storage_type" {
  type    = string
  default = "io1"
}
variable "rds_postgres_kms_key_arn" {
  type    = string
  default = null
}
variable "rds_postgres_replication_database_arn" {
  type    = string
  default = null
}
variable "rds_postgres_backup_retention_period" {
  type    = number
  default = null
}

## Praefect PostgreSQL
variable "rds_praefect_postgres_instance_type" {
  type    = string
  default = ""
}
variable "rds_praefect_postgres_port" {
  type    = number
  default = 5432
}
variable "rds_praefect_postgres_username" {
  type    = string
  default = "praefect"
}
variable "rds_praefect_postgres_password" {
  type    = string
  default = ""
}
variable "rds_praefect_postgres_database_name" {
  type    = string
  default = "praefect_production"
}
variable "rds_praefect_postgres_version" {
  type    = string
  default = "12.6"
}
variable "rds_praefect_postgres_allocated_storage" {
  type    = number
  default = 100
}
variable "rds_praefect_postgres_max_allocated_storage" {
  type    = number
  default = 1000
}
variable "rds_praefect_postgres_multi_az" {
  type    = bool
  default = true
}
variable "rds_praefect_postgres_iops" {
  type    = number
  default = 1000
}
variable "rds_praefect_postgres_storage_type" {
  type    = string
  default = "io1"
}
variable "rds_praefect_postgres_kms_key_arn" {
  type    = string
  default = null
}
variable "rds_praefect_postgres_backup_retention_period" {
  type    = number
  default = null
}

## Geo Tracking PostgreSQL
variable "rds_geo_tracking_postgres_instance_type" {
  type    = string
  default = ""
}
variable "rds_geo_tracking_postgres_port" {
  type    = number
  default = 5431
}
variable "rds_geo_tracking_postgres_username" {
  type    = string
  default = "praefect"
}
variable "rds_geo_tracking_postgres_password" {
  type    = string
  default = ""
}
variable "rds_geo_tracking_postgres_database_name" {
  type    = string
  default = "gitlabhq_geo_production"
}
variable "rds_geo_tracking_postgres_version" {
  type    = string
  default = "12.6"
}
variable "rds_geo_tracking_postgres_allocated_storage" {
  type    = number
  default = 100
}
variable "rds_geo_tracking_postgres_max_allocated_storage" {
  type    = number
  default = 1000
}
variable "rds_geo_tracking_postgres_multi_az" {
  type    = bool
  default = true
}
variable "rds_geo_tracking_postgres_iops" {
  type    = number
  default = 1000
}
variable "rds_geo_tracking_postgres_storage_type" {
  type    = string
  default = "io1"
}
variable "rds_geo_tracking_postgres_kms_key_arn" {
  type    = string
  default = null
}
variable "rds_geo_tracking_postgres_backup_retention_period" {
  type    = number
  default = null
}

## Redis
### Combined
variable "elasticache_redis_node_count" {
  type    = number
  default = 0
}
variable "elasticache_redis_instance_type" {
  type    = string
  default = ""
}
variable "elasticache_redis_kms_key_arn" {
  type    = string
  default = null
}

variable "elasticache_redis_engine_version" {
  type    = string
  default = "6.x"
}
variable "elasticache_redis_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "elasticache_redis_port" {
  type    = number
  default = 6379
}
variable "elasticache_redis_multi_az" {
  type    = bool
  default = true
}

### Separate - Cache
variable "elasticache_redis_cache_node_count" {
  type    = number
  default = 0
}
variable "elasticache_redis_cache_instance_type" {
  type    = string
  default = ""
}
variable "elasticache_redis_cache_kms_key_arn" {
  type    = string
  default = null
}

variable "elasticache_redis_cache_engine_version" {
  type    = string
  default = null
}
variable "elasticache_redis_cache_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "elasticache_redis_cache_port" {
  type    = number
  default = null
}
variable "elasticache_redis_cache_multi_az" {
  type    = bool
  default = null
}

### Separate - Persistent
variable "elasticache_redis_persistent_node_count" {
  type    = number
  default = 0
}
variable "elasticache_redis_persistent_instance_type" {
  type    = string
  default = ""
}
variable "elasticache_redis_persistent_kms_key_arn" {
  type    = string
  default = null
}

variable "elasticache_redis_persistent_engine_version" {
  type    = string
  default = null
}
variable "elasticache_redis_persistent_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "elasticache_redis_persistent_port" {
  type    = number
  default = null
}
variable "elasticache_redis_persistent_multi_az" {
  type    = bool
  default = null
}

# Networking
## Create new network
variable "create_network" {
  type    = bool
  default = false
}
variable "vpc_cidr_block" {
  type    = string
  default = "172.31.0.0/16"
}
variable "subpub_pub_cidr_block" {
  type    = list(string)
  default = ["172.31.0.0/20", "172.31.16.0/20", "172.31.32.0/20"]
}
variable "subnet_pub_count" {
  type    = number
  default = 2
}

## Existing network
variable "vpc_id" {
  type    = string
  default = null
}
variable "subnet_ids" {
  type    = list(string)
  default = null
}

## Default Network
variable "default_subnet_use_count" {
  type    = number
  default = 2
}
