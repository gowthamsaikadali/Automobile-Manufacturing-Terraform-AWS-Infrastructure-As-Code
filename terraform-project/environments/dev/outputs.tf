output "alb_dns_name" {
  description = "Public URL to access your app — open this in a browser"
  value       = "http://${module.alb.alb_dns_name}"
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "db_endpoint" {
  value = module.database.db_endpoint
}

output "db_secret_arn" {
  description = "Fetch credentials with: aws secretsmanager get-secret-value --secret-id <this-arn>"
  value       = module.database.secret_arn
}

output "asg_name" {
  value = module.compute.asg_name
}
