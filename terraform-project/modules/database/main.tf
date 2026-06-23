###############################################################################
# DATABASE MODULE
# Creates: DB subnet group (private subnets only), RDS instance,
#          and a Secrets Manager secret holding the connection credentials
#          (so the app pulls creds at boot instead of them sitting in
#          plaintext in user_data or tfvars).
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  port        = var.db_engine == "postgres" ? 5432 : 3306
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name        = "${local.name_prefix}-db-subnet-group"
    Environment = var.environment
  }
}

# Auto-generate a strong password if the caller didn't supply one
resource "random_password" "db_password" {
  count            = var.db_password == "" ? 1 : 0
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  final_db_password = var.db_password != "" ? var.db_password : random_password.db_password[0].result
}

resource "aws_db_instance" "main" {
  identifier     = "${local.name_prefix}-db"
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = local.final_db_password
  port     = local.port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false # private subnet — never internet-reachable

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-final-snapshot"
  deletion_protection     = var.deletion_protection

  auto_minor_version_upgrade = true
  apply_immediately          = true # dev convenience; consider false for prod maintenance windows

  tags = {
    Name        = "${local.name_prefix}-db"
    Environment = var.environment
  }
}

# Store the live connection info centrally — EC2 reads this at boot via IAM role
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.name_prefix}-db-credentials"
  recovery_window_in_days = 0 # immediate delete on destroy, convenient for dev/test

  tags = {
    Name        = "${local.name_prefix}-db-credentials"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = local.final_db_password
    host     = aws_db_instance.main.address
    port     = local.port
    dbname   = var.db_name
    engine   = var.db_engine
    # Convenience field: a ready-to-use SQLAlchemy URI for Flask's config.py
    database_url = var.db_engine == "postgres" ? "postgresql://${var.db_username}:${local.final_db_password}@${aws_db_instance.main.address}:${local.port}/${var.db_name}" : "mysql+pymysql://${var.db_username}:${local.final_db_password}@${aws_db_instance.main.address}:${local.port}/${var.db_name}"
  })
}
