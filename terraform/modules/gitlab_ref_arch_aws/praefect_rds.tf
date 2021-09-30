locals {
  create_praefect_kms_key  = var.rds_praefect_postgres_instance_type != "" && var.rds_praefect_postgres_kms_key_arn == null
  create_praefect_resource = var.rds_praefect_postgres_instance_type != "" ? 1 : 0
}

resource "aws_db_subnet_group" "gitlab_praefect" {
  count      = local.create_praefect_resource
  name       = "${var.prefix}-praefect-rds-subnet-group"
  subnet_ids = coalesce(local.subnet_ids, local.default_subnet_ids)

  tags = {
    Name = "${var.prefix}-praefect-rds-subnet-group"
  }
}

resource "aws_kms_key" "gitlab_praefect_kms_key" {
  count = local.create_praefect_kms_key ? 1 : 0

  description = "${var.prefix} RDS Praefect Postgres KMS Key"

  tags = {
    Name = "${var.prefix}-rds-praefect-postgres-kms-key"
  }
}

resource "aws_db_instance" "gitlab_praefect" {
  count = local.create_praefect_resource

  identifier     = "${var.prefix}-rds-praefect"
  engine         = "postgres"
  engine_version = var.rds_praefect_postgres_version
  instance_class = "db.${var.rds_praefect_postgres_instance_type}"
  multi_az       = var.rds_praefect_postgres_multi_az
  iops           = var.rds_praefect_postgres_iops
  storage_type   = var.rds_praefect_postgres_storage_type

  name     = var.rds_praefect_postgres_database_name
  port     = var.rds_praefect_postgres_port
  username = var.rds_praefect_postgres_username
  password = var.rds_praefect_postgres_password

  db_subnet_group_name = aws_db_subnet_group.gitlab_praefect[0].name
  vpc_security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]

  allocated_storage       = var.rds_praefect_postgres_allocated_storage
  max_allocated_storage   = var.rds_praefect_postgres_max_allocated_storage
  storage_encrypted       = true
  kms_key_id              = local.create_praefect_kms_key ? aws_kms_key.gitlab_praefect_kms_key[0].arn : var.rds_praefect_postgres_kms_key_arn
  backup_retention_period = var.rds_praefect_postgres_backup_retention_period

  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = false

  skip_final_snapshot = true
}

output "rds_praefect_postgres_connection" {
  value = {
    "rds_address"           = try(aws_db_instance.gitlab_praefect[0].address, "")
    "rds_port"              = try(aws_db_instance.gitlab_praefect[0].port, "")
    "rds_database_name"     = try(aws_db_instance.gitlab_praefect[0].name, "")
    "rds_database_username" = try(aws_db_instance.gitlab_praefect[0].username, "")
    "rds_database_arn"      = try(aws_db_instance.gitlab_praefect[0].arn, "")
    "rds_kms_key_arn"       = try(aws_db_instance.gitlab_praefect[0].kms_key_id, "")
  }
}
