variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into EC2 directly. CHANGE to your IP/32 — never leave as 0.0.0.0/0 in real use."
  type        = string
}

variable "app_port" {
  description = "Port your Gunicorn/Flask app listens on internally (ALB -> EC2)"
  type        = number
  default     = 8000
}

variable "db_port" {
  description = "Database port (3306 = MySQL, 5432 = PostgreSQL)"
  type        = number
  default     = 3306
}
