output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = local.port
}

output "db_name" {
  value = var.db_name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}
