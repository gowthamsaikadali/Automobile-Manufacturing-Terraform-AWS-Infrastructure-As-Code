variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "iam_instance_profile_name" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro" # free-tier eligible
}

variable "ami_id" {
  description = "AMI ID to use. Leave empty to auto-select latest Ubuntu 22.04 LTS via data source."
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH access. CHANGE ME — must already exist in your AWS account/region."
  type        = string
}

variable "app_port" {
  type    = number
  default = 8000
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "git_repo_url" {
  description = "HTTPS Git URL of your automobile-manufacturing-app repo. CHANGE ME."
  type        = string
}

variable "git_branch" {
  type    = string
  default = "main"
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN holding DB credentials, passed to user_data so the instance knows what to fetch"
  type        = string
}

variable "aws_region" {
  type = string
}
