# General
variable "prefix" {
  type    = string
  default = null
}

variable "image_id" {
  type    = string
  default = null
}

variable "default_disk_size" {
  type    = string
  default = "100"
}
variable "default_disk_type" {
  type    = string
  default = "CLOUD_PREMIUM"
}

variable "default_cpu_core_count" {
  type    = string
  default = "2"
}
variable "default_memory_size" {
  type    = string
  default = "4"
}
variable "default_instance_type" {
  type    = string
  default = "S5.MEDIUM4"
}

variable "ssh_key" {
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
  default = "CLOUD_SSD"
}
variable "elastic_disk_size" {
  type    = string
  default = "500"
}
variable "elastic_data_disk_size" {
  type    = string
  default = "500"
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
  default = "CLOUD_SSD"
}
variable "gitaly_disk_size" {
  type    = string
  default = "500"
}
variable "gitaly_data_disk_size" {
  type    = string
  default = "500"
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

# VPC
variable "vpc_name" {
  type    = string
  default = "vpc"
}
variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}
variable "subnet_name" {
  type    = string
  default = "subnet"
}
variable "subnet_cidr" {
  type    = string
  default = "172.16.0.0/24"
}

# K8s
variable "k8s_cluster_cidr" {
  type    = string
  default = "10.0.0.0/24"
}
variable "k8s_subnet_cidr" {
  type    = string
  default = "172.16.1.0/24"
}
variable "k8s_worker_password" {
  type      = string
  default   = null
  sensitive = true
}
variable "k8s_worker_number" {
  type    = number
  default = 3
}
variable "k8s_cluster_os" {
  type    = string
  default = "ubuntu18.04.1 LTSx86_64"
}
variable "k8s_cluster_version" {
  type    = string
  default = "1.18.4"
}
