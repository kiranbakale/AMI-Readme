locals {
  rds_geo_tracking_postgres_create = var.rds_geo_tracking_postgres_instance_type != ""

  rds_geo_tracking_postgres_subnet_ids = local.backend_subnet_ids != null ? local.backend_subnet_ids : slice(tolist(local.default_subnet_ids), 0, var.rds_geo_tracking_default_subnet_count)
}

data "aws_kms_key" "aws_geo_rds" {
  count = local.rds_geo_tracking_postgres_create && var.rds_geo_tracking_postgres_kms_key_arn == null && var.default_kms_key_arn == null ? 1 : 0

  key_id = "alias/aws/rds"
}

resource "aws_db_subnet_group" "gitlab_geo" {
  count      = local.rds_geo_tracking_postgres_create ? 1 : 0
  name       = "${var.prefix}-geo-rds-subnet-group"
  subnet_ids = local.rds_geo_tracking_postgres_subnet_ids

  tags = {
    Name = "${var.prefix}-geo-rds-subnet-group"
  }
}

resource "aws_db_instance" "gitlab_geo_tracking" {
  count = local.rds_geo_tracking_postgres_create ? 1 : 0

  identifier     = "${var.prefix}-rds-geo-tracking"
  engine         = "postgres"
  engine_version = var.rds_geo_tracking_postgres_version
  instance_class = "db.${var.rds_geo_tracking_postgres_instance_type}"
  multi_az       = var.rds_geo_tracking_postgres_multi_az
  iops           = var.rds_geo_tracking_postgres_iops
  storage_type   = var.rds_geo_tracking_postgres_storage_type

  name     = var.rds_geo_tracking_postgres_database_name
  port     = var.rds_geo_tracking_postgres_port
  username = var.rds_geo_tracking_postgres_username
  password = var.rds_geo_tracking_postgres_password

  iam_database_authentication_enabled = true

  db_subnet_group_name = aws_db_subnet_group.gitlab_geo[0].name
  vpc_security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]

  allocated_storage     = var.rds_geo_tracking_postgres_allocated_storage
  max_allocated_storage = var.rds_geo_tracking_postgres_max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = coalesce(var.rds_geo_tracking_postgres_kms_key_arn, var.default_kms_key_arn, try(data.aws_kms_key.aws_geo_rds[0].arn, null))

  backup_window           = var.rds_geo_tracking_postgres_backup_window
  backup_retention_period = var.rds_geo_tracking_postgres_backup_retention_period

  allow_major_version_upgrade = true

  skip_final_snapshot = true
}

output "rds_geo_tracking_postgres_connection" {
  value = {
    "rds_geo_host"              = try(aws_db_instance.gitlab_geo_tracking[0].address, "")
    "rds_geo_port"              = try(aws_db_instance.gitlab_geo_tracking[0].port, "")
    "rds_geo_database_name"     = try(aws_db_instance.gitlab_geo_tracking[0].name, "")
    "rds_geo_database_username" = try(aws_db_instance.gitlab_geo_tracking[0].username, "")
    "rds_geo_database_arn"      = try(aws_db_instance.gitlab_geo_tracking[0].arn, "")
    "rds_geo_kms_key_arn"       = try(aws_db_instance.gitlab_geo_tracking[0].kms_key_id, "")
    "rds_geo_version"           = try(aws_db_instance.gitlab_geo_tracking[0].engine_version_actual, "")
  }
}
