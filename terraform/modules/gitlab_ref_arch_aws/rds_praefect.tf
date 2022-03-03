locals {
  rds_praefect_postgres_create = var.rds_praefect_postgres_instance_type != ""

  rds_praefect_postgres_subnet_ids = local.backend_subnet_ids != null ? local.backend_subnet_ids : slice(tolist(local.default_subnet_ids), 0, var.rds_praefect_postgres_default_subnet_count)
}

resource "aws_db_subnet_group" "gitlab_praefect" {
  count      = local.rds_praefect_postgres_create ? 1 : 0
  name       = "${var.prefix}-praefect-rds-subnet-group"
  subnet_ids = local.rds_praefect_postgres_subnet_ids

  tags = {
    Name = "${var.prefix}-praefect-rds-subnet-group"
  }
}

resource "aws_db_instance" "gitlab_praefect" {
  count = local.rds_praefect_postgres_create ? 1 : 0

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

  iam_database_authentication_enabled = true

  db_subnet_group_name = aws_db_subnet_group.gitlab_praefect[0].name
  vpc_security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]

  allocated_storage     = var.rds_praefect_postgres_allocated_storage
  max_allocated_storage = var.rds_praefect_postgres_max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = coalesce(var.rds_praefect_postgres_kms_key_arn, var.default_kms_key_arn, try(data.aws_kms_key.aws_rds[0].arn, null))

  backup_window           = var.rds_praefect_postgres_backup_window
  backup_retention_period = var.rds_praefect_postgres_backup_retention_period

  allow_major_version_upgrade = true

  skip_final_snapshot = true
}

output "rds_praefect_postgres_connection" {
  value = {
    "rds_praefect_host"              = try(aws_db_instance.gitlab_praefect[0].address, "")
    "rds_praefect_port"              = try(aws_db_instance.gitlab_praefect[0].port, "")
    "rds_praefect_database_name"     = try(aws_db_instance.gitlab_praefect[0].name, "")
    "rds_praefect_database_username" = try(aws_db_instance.gitlab_praefect[0].username, "")
    "rds_praefect_database_arn"      = try(aws_db_instance.gitlab_praefect[0].arn, "")
    "rds_praefect_kms_key_arn"       = try(aws_db_instance.gitlab_praefect[0].kms_key_id, "")
  }
}
