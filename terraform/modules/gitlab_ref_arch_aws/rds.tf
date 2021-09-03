locals {
  create_kms_key = var.rds_postgres_instance_type != "" && var.rds_postgres_kms_key_arn == null
}

resource "aws_db_subnet_group" "gitlab" {
  count      = var.rds_postgres_instance_type != "" ? 1 : 0
  name       = "${var.prefix}-rds-subnet-group"
  subnet_ids = coalesce(local.subnet_ids, local.default_subnet_ids)

  tags = {
    Name = "${var.prefix}-rds-subnet-group"
  }
}

resource "aws_kms_key" "gitlab_kms_key" {
  count = local.create_kms_key ? 1 : 0

  description = "${var.prefix} RDS Postgres KMS Key"

  tags = {
    Name = "${var.prefix}-rds-postgres-kms-key"
  }
}

resource "aws_db_instance" "gitlab" {
  count = var.rds_postgres_instance_type != "" ? 1 : 0

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

  allocated_storage     = var.rds_postgres_allocated_storage
  max_allocated_storage = var.rds_postgres_max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = local.create_kms_key ? aws_kms_key.gitlab_kms_key[0].arn : var.rds_postgres_kms_key_arn

  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = false

  skip_final_snapshot = true
}

output "rds_connection" {
  value = {
    "rds_address"           = try(aws_db_instance.gitlab[0].address, "")
    "rds_port"              = try(aws_db_instance.gitlab[0].port, "")
    "rds_database_name"     = try(aws_db_instance.gitlab[0].name, "")
    "rds_database_username" = try(aws_db_instance.gitlab[0].username, "")
    "rds_kms_key_arn"       = try(aws_db_instance.gitlab[0].kms_key_id, "")
  }
}
