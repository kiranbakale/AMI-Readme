locals {
  rds_postgres_create = var.rds_postgres_instance_type != ""

  rds_postgres_subnet_ids = local.subnet_ids != null ? local.subnet_ids : slice(tolist(local.default_subnet_ids), 0, var.rds_postgres_default_subnet_count)
}

resource "aws_db_subnet_group" "gitlab" {
  count      = local.rds_postgres_create ? 1 : 0
  name       = "${var.prefix}-rds-subnet-group"
  subnet_ids = local.rds_postgres_subnet_ids

  tags = {
    Name = "${var.prefix}-rds-subnet-group"
  }
}

# aws_db_instance doesn't look to follow standard null design for kms_key_id - will ignore changes
# This ensures default key is used
data "aws_kms_key" "aws_rds" {
  count = local.rds_postgres_create && var.rds_postgres_kms_key_arn == null && var.default_kms_key_arn == null ? 1 : 0

  key_id = "alias/aws/rds"
}

resource "aws_db_instance" "gitlab" {
  count = local.rds_postgres_create ? 1 : 0

  identifier     = "${var.prefix}-rds"
  engine         = "postgres"
  engine_version = var.rds_postgres_version
  instance_class = "db.${var.rds_postgres_instance_type}"
  multi_az       = var.rds_postgres_multi_az
  iops           = var.rds_postgres_iops
  storage_type   = var.rds_postgres_storage_type

  name                 = var.rds_postgres_database_name
  port                 = var.rds_postgres_port
  username             = var.rds_postgres_username
  password             = var.rds_postgres_password
  db_subnet_group_name = aws_db_subnet_group.gitlab[0].name
  vpc_security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]

  replicate_source_db = var.rds_postgres_replication_database_arn
  apply_immediately   = true

  allocated_storage     = var.rds_postgres_allocated_storage
  max_allocated_storage = var.rds_postgres_max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = coalesce(var.rds_postgres_kms_key_arn, var.default_kms_key_arn, data.aws_kms_key.aws_rds[0].arn)

  backup_window           = var.rds_postgres_backup_window
  backup_retention_period = var.rds_postgres_backup_retention_period

  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = false

  skip_final_snapshot = true

  lifecycle {
    ignore_changes = [
      replicate_source_db
    ]
  }
}

output "rds_postgres_connection" {
  value = {
    "rds_host"              = try(aws_db_instance.gitlab[0].address, "")
    "rds_port"              = try(aws_db_instance.gitlab[0].port, "")
    "rds_database_name"     = try(aws_db_instance.gitlab[0].name, "")
    "rds_database_username" = try(aws_db_instance.gitlab[0].username, "")
    "rds_database_arn"      = try(aws_db_instance.gitlab[0].arn, "")
    "rds_kms_key_arn"       = try(aws_db_instance.gitlab[0].kms_key_id, "")
  }
}
