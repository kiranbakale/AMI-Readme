# General
variable "prefix" { default = null }

variable "image_id" { default = null }

variable "default_disk_size" { default = "100" }
variable "default_disk_type" { default = "CLOUD_PREMIUM" }

variable "default_cpu_core_count" { default = "2" }
variable "default_memory_size" { default = "4" }
variable "default_instance_type" { default = "S5.MEDIUM4" }

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
variable "elastic_disk_type" { default = "CLOUD_SSD" }
variable "elastic_disk_size" { default = "500" }
variable "elastic_data_disk_size" { default = "500" }

variable "gitaly_node_count" { default = 0 }
variable "gitaly_instance_type" { default = "" }
variable "gitaly_disk_type" { default = "CLOUD_SSD" }
variable "gitaly_disk_size" { default = "500" }
variable "gitaly_data_disk_size" { default = "500" }

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
variable "postgres_data_disk_size" { default = null }

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
variable "redis_data_disk_size" { default = null }

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

# VPC
variable "vpc_name" { default = "vpc" }
variable "vpc_cidr" { default = "172.16.0.0/16" }
variable "subnet_name" { default = "subnet" }
variable "subnet_cidr" { default = "172.16.0.0/24" }

# K8s
variable "k8s_cluster_cidr" { default = "10.0.0.0/24" }
variable "k8s_subnet_cidr" { default = "172.16.1.0/24" }
variable "k8s_worker_password" { default = null }
variable "k8s_worker_number" { default = 3 }
variable "k8s_cluster_os" { default = "ubuntu18.04.1 LTSx86_64" }
variable "k8s_cluster_version" { default = "1.18.4" }
