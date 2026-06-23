variable "project_name" {
  description = "Project name, used in resource naming/tags"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "List of CIDRs for private application subnets (one per AZ)"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "List of CIDRs for private database subnets (one per AZ)"
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones to spread subnets across"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnet internet egress (costs money — disable for cheapest dev setup)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT Gateway instead of one per AZ (cheaper, less resilient — good for dev)"
  type        = bool
  default     = true
}
