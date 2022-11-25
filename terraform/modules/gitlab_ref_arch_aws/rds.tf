locals {
  rds_postgres_create = var.rds_postgres_instance_type != ""

  rds_postgres_subnet_ids    = local.backend_subnet_ids != null ? local.backend_subnet_ids : slice(tolist(local.default_subnet_ids), 0, var.rds_postgres_default_subnet_count)
  rds_postgres_major_version = floor(var.rds_postgres_version)
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

resource "aws_db_parameter_group" "gitlab" {
  count = local.rds_postgres_create ? 1 : 0

  name_prefix = "${var.prefix}-rds-pg${local.rds_postgres_major_version}-"
  family      = "postgres${local.rds_postgres_major_version}"

  parameter {
    name  = "password_encryption"
    value = "scram-sha-256"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = 1000
  }

  lifecycle {
    create_before_destroy = true
  }
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

  db_name  = var.rds_postgres_database_name
  port     = var.rds_postgres_port
  username = var.rds_postgres_username
  password = var.rds_postgres_password

  iam_database_authentication_enabled = true

  db_subnet_group_name = aws_db_subnet_group.gitlab[0].name
  vpc_security_group_ids = [
    aws_security_group.gitlab_rds[0].id
  ]

  parameter_group_name = aws_db_parameter_group.gitlab[0].name
  replicate_source_db  = var.rds_postgres_replication_database_arn
  apply_immediately    = true

  allocated_storage     = var.rds_postgres_allocated_storage
  max_allocated_storage = var.rds_postgres_max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = coalesce(var.rds_postgres_kms_key_arn, var.default_kms_key_arn, try(data.aws_kms_key.aws_rds[0].arn, null))

  backup_window           = var.rds_postgres_backup_window
  backup_retention_period = var.rds_postgres_backup_retention_period
  maintenance_window      = var.rds_postgres_maintenance_window

  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = var.rds_postgres_auto_minor_version_upgrade

  skip_final_snapshot = true

  delete_automated_backups = var.rds_postgres_delete_automated_backups

  copy_tags_to_snapshot = true
  tags                  = var.rds_postgres_tags
}

resource "aws_db_instance" "gitlab_read_replica" {
  count = local.rds_postgres_create ? var.rds_postgres_read_replica_count : 0

  identifier     = "${format("%.47s", var.prefix)}-rds-read-rep-${count.index + 1}"
  instance_class = aws_db_instance.gitlab[0].instance_class
  iops           = aws_db_instance.gitlab[0].iops
  storage_type   = aws_db_instance.gitlab[0].storage_type

  port     = var.rds_postgres_read_replica_port
  multi_az = var.rds_postgres_read_replica_multi_az

  db_subnet_group_name = aws_db_subnet_group.gitlab[0].name
  vpc_security_group_ids = [
    aws_security_group.gitlab_rds[0].id
  ]

  parameter_group_name = aws_db_parameter_group.gitlab[0].name
  replicate_source_db  = aws_db_instance.gitlab[0].arn
  apply_immediately    = true

  allocated_storage     = aws_db_instance.gitlab[0].allocated_storage
  max_allocated_storage = aws_db_instance.gitlab[0].max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = aws_db_instance.gitlab[0].kms_key_id

  allow_major_version_upgrade = aws_db_instance.gitlab[0].allow_major_version_upgrade
  auto_minor_version_upgrade  = aws_db_instance.gitlab[0].auto_minor_version_upgrade

  skip_final_snapshot     = true
  copy_tags_to_snapshot   = true
  backup_retention_period = 0

  tags = var.rds_postgres_tags
}

output "rds_postgres_connection" {
  value = {
    "rds_host"               = try(aws_db_instance.gitlab[0].address, "")
    "rds_port"               = try(aws_db_instance.gitlab[0].port, "")
    "rds_database_name"      = try(aws_db_instance.gitlab[0].db_name, "")
    "rds_database_username"  = try(aws_db_instance.gitlab[0].username, "")
    "rds_database_arn"       = try(aws_db_instance.gitlab[0].arn, "")
    "rds_kms_key_arn"        = try(aws_db_instance.gitlab[0].kms_key_id, "")
    "rds_version"            = try(aws_db_instance.gitlab[0].engine_version_actual, "")
    "rds_read_replica_hosts" = try(aws_db_instance.gitlab_read_replica[*].address, "")
  }
}
