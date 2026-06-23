variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8000
}

variable "health_check_path" {
  description = "Path Flask app responds 200 OK on, used for ALB target group health checks"
  type        = string
  default     = "/health" # matches the GET /health endpoint with DB probe described in PRODUCTION_CHANGES.md
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener. Leave empty to skip HTTPS (HTTP-only ALB) — fine for dev/testing."
  type        = string
  default     = ""
}
