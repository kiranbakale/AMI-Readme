locals {
  create_postgres_kms_key  = var.rds_postgres_instance_type != "" && var.rds_postgres_kms_key_arn == null
  create_postgres_resource = var.rds_postgres_instance_type != "" ? 1 : 0
}

resource "aws_db_subnet_group" "gitlab" {
  count      = local.create_postgres_resource
  name       = "${var.prefix}-rds-subnet-group"
  subnet_ids = coalesce(local.subnet_ids, local.default_subnet_ids)

  tags = {
    Name = "${var.prefix}-rds-subnet-group"
  }
}

resource "aws_kms_key" "gitlab_rds_postgres_kms_key" {
  count = local.create_postgres_kms_key ? 1 : 0

  description = "${var.prefix} RDS Postgres KMS Key"

  tags = {
    Name = "${var.prefix}-rds-postgres-kms-key"
  }
}

resource "aws_db_instance" "gitlab" {
  count = local.create_postgres_resource

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

  allocated_storage       = var.rds_postgres_allocated_storage
  max_allocated_storage   = var.rds_postgres_max_allocated_storage
  storage_encrypted       = true
  kms_key_id              = local.create_postgres_kms_key ? aws_kms_key.gitlab_rds_postgres_kms_key[0].arn : var.rds_postgres_kms_key_arn
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
    "rds_address"           = try(aws_db_instance.gitlab[0].address, "")
    "rds_port"              = try(aws_db_instance.gitlab[0].port, "")
    "rds_database_name"     = try(aws_db_instance.gitlab[0].name, "")
    "rds_database_username" = try(aws_db_instance.gitlab[0].username, "")
    "rds_database_arn"      = try(aws_db_instance.gitlab[0].arn, "")
    "rds_kms_key_arn"       = try(aws_db_instance.gitlab[0].kms_key_id, "")
  }
}
