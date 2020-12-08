module "gitlab_ref_arch_aws" {
  source = "../modules/gitlab_ref_arch_aws"

  prefix = var.prefix
  ssh_key = file(var.ssh_key_path)

  # 10k
  consul_node_count = 3
  consul_instance_type = "c5.large"

  gitaly_node_count = 2
  gitaly_instance_type = "m5.4xlarge"

  gitlab_nfs_node_count = 1
  gitlab_nfs_instance_type = "c5.xlarge"

  gitlab_rails_node_count = 3
  gitlab_rails_instance_type = "c5.9xlarge"

  haproxy_external_node_count = 1
  haproxy_external_instance_type = "c5.large"
  haproxy_external_elastic_ip_allocation_ids = ["eipalloc-0afb5cb5220df81c2"]
  haproxy_internal_node_count = 1
  haproxy_internal_instance_type = "c5.large"

  monitor_node_count = 1
  monitor_instance_type = "c5.xlarge"

  pgbouncer_node_count = 3
  pgbouncer_instance_type = "c5.large"

  postgres_node_count = 3
  postgres_instance_type = "m5.xlarge"

  redis_cache_node_count = 3
  redis_cache_instance_type = "m5.xlarge"
  redis_sentinel_cache_node_count = 3
  redis_sentinel_cache_instance_type = "t3.small"
  redis_persistent_node_count = 3
  redis_persistent_instance_type = "m5.xlarge"
  redis_sentinel_persistent_node_count = 3
  redis_sentinel_persistent_instance_type = "t3.small"

  sidekiq_node_count = 3
  sidekiq_instance_type = "m5.xlarge"
}

output "gitlab_ref_arch_aws" {
  value = module.gitlab_ref_arch_aws
}