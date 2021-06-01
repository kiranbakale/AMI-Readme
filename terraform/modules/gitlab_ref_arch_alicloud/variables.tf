# General
variable "prefix" { default = null }

variable "image_id" { default = "ubuntu_18_04_64_20G_alibase_20190624.vhd" }

variable "default_disk_size" { default = "100" }
variable "default_disk_type" { default = "cloud_essd" }

variable "default_cpu_core_count" { default = "2" }
variable "default_memory_size" { default = "8" }
variable "instance_type_family" { default = "ecs.hfg7" }

variable "ssh_key" { default = null }

variable "geo_site" { default = null }
variable "geo_deployment" { default = null }

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

# VPC
variable "vpc_cidr" { default = "172.16.0.0/12" }
variable "vswitch_cidr" { default = "172.16.0.0/24" }


# K8s
# VSwitch variables
variable "k8s_vswitch_cidr" {
  description = "List of cidr blocks used to create several new vswitches when 'vswitch_ids' is not specified."
  default     = "172.16.1.0/24"
}

variable "worker_instance_type" {
  description = "The ecs instance type used to launch worker nodes. Default from instance typs datasource."
  default     = ""
}

variable "worker_disk_category" {
  description = "The system disk category used to launch one or more worker nodes."
  default     = "cloud_essd"
}

variable "worker_disk_size" {
  description = "The system disk size used to launch one or more worker nodes."
  default     = "50"
}

variable "ecs_password" {
  description = "The password of instance."
  default     = ""
}

variable "k8s_number" {
  description = "The number of kubernetes cluster."
  default     = 1
}

variable "k8s_worker_number" {
  description = "The number of worker nodes in each kubernetes cluster."
  default     = 3
}

variable "k8s_name_prefix" {
  description = "The name prefix used to create several kubernetes clusters. Default to variable `example_name`"
  default     = ""
}

# Follow https://www.alibabacloud.com/help/zh/doc-detail/86500.htm?spm=a2c63.p38356.879954.15.204e657dnW4wxT#title-ovl-upk-yam
variable "k8s_pod_cidr" {
  description = "The kubernetes pod cidr block. It cannot be equals to vpc's or vswitch's and cannot be in them."
  default     = "192.168.0.0/16"
}

variable "k8s_service_cidr" {
  description = "The kubernetes service cidr block. It cannot be equals to vpc's or vswitch's or pod's and cannot be in them."
  default     = "10.0.0.0/24"
}
