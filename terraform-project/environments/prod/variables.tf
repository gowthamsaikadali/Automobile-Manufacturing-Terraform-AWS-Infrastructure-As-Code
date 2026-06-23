###############################################################################
# VARIABLE DECLARATIONS — actual values live in terraform.tfvars (or
# dev.tfvars / prod.tfvars). This file just declares types/defaults/docs.
###############################################################################

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "forgepoint"
}

variable "environment" {
  type    = string
  default = "dev"
}

# --- Networking -------------------------------------------------------------
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_db_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "enable_nat_gateway" {
  description = "NAT Gateway costs ~$32/mo + data — set false to save money in dev if your app doesn't need outbound internet from private subnet (it does need it to clone git/pip install, so keep true unless you use VPC endpoints instead)."
  type        = bool
  default     = true
}

# --- Security ----------------------------------------------------------------
variable "ssh_allowed_cidr" {
  description = "YOUR IP in CIDR form, e.g. 103.21.45.10/32. CHANGE ME. Get it via: curl ifconfig.me"
  type        = string
  default     = "0.0.0.0/0" # <<< CHANGE ME before applying — this default is wide open
}

# --- Compute -------------------------------------------------------------
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name in this region. CHANGE ME — create via: aws ec2 create-key-pair --key-name forgepoint-key"
  type        = string
}

variable "app_port" {
  description = "Internal port nginx/gunicorn listens on, that the ALB forwards to"
  type        = number
  default     = 8000
}

variable "git_repo_url" {
  description = "HTTPS URL to your automobile-manufacturing-app git repo. CHANGE ME."
  type        = string
}

variable "git_branch" {
  type    = string
  default = "main"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "desired_capacity" {
  type    = number
  default = 1
}

# --- Database ----------------------------------------------------------------
variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_engine_version" {
  type    = string
  default = "8.0.36"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_name" {
  type    = string
  default = "forgepoint"
}

variable "db_username" {
  type      = string
  sensitive = true
  default   = "forgepoint_admin"
}

variable "db_password" {
  description = "Leave empty to auto-generate via random_password (recommended). Or set via TF_VAR_db_password env var — never commit a real password to tfvars."
  type        = string
  sensitive   = true
  default     = ""
}

# --- ALB / TLS -----------------------------------------------------------
variable "certificate_arn" {
  description = "ACM cert ARN for HTTPS. Leave empty for HTTP-only ALB (fine for dev)."
  type        = string
  default     = ""
}

variable "health_check_path" {
  type    = string
  default = "/health"
}
