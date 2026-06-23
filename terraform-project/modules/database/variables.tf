variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "db_engine" {
  description = "mysql or postgres"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  type    = string
  default = "8.4.8"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro" # Free-tier-eligible; bump for prod
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  description = "Initial database name (must match config.py / .env expectations)"
  type        = string
  default     = "database"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  description = "Leave blank to let Terraform auto-generate and store a random password in Secrets Manager (recommended)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability. Set true for prod, false for dev (saves cost)."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  type    = number
  default = 0
}

variable "skip_final_snapshot" {
  description = "true = data lost on destroy (fine for dev). false for prod."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  type    = bool
  default = false
}
