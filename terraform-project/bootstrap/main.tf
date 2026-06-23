###############################################################################
# BOOTSTRAP — run this ONCE, manually, before anything else
#
# This creates the S3 bucket + DynamoDB table that the REST of the project
# (environments/dev, environments/prod) will use as a remote backend.
#
# Why separate? Terraform can't create its own backend and use it in the same
# `terraform init` — the backend must already exist. So this tiny config is
# applied with LOCAL state once, and after that you never touch it again.
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Intentionally NO backend block here — this uses local state on purpose.
}

provider "aws" {
  region = var.aws_region

  # <<< CHANGE ME: your AWS provider auth. See README "Provider credentials".
  # Easiest for now: leave this blank and export env vars, or use `aws configure`.
  # profile = "your-aws-cli-profile"
}

variable "aws_region" {
  description = "AWS region to create the backend resources in"
  type        = string
  default     = "ap-south-1" # Mumbai — change if you want a different home region
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform state. CHANGE THIS."
  type        = string
  default     = "gowthamstatefile2026" # <<< CHANGE ME (must be globally unique)
}

variable "lock_table_name" {
  description = "DynamoDB table name used for state locking"
  type        = string
  default     = "tfstatelocks"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket_name

  # Prevents `terraform destroy` from ever nuking your state bucket by accident
  /*lifecycle {
    prevent_destroy = true
  }*/

  tags = {
    Name      = "Terraform State Bucket"
    ManagedBy = "Terraform"
    Project   = "automobile-project"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled" # lets you roll back state if something corrupts it
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST" # no fixed cost, scales to zero
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform Lock Table"
    ManagedBy = "Terraform"
    Project   = "automobile-project"
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.tf_locks.name
}

output "backend_config_snippet" {
  description = "Copy this into environments/dev/backend.tf and environments/prod/backend.tf"
  value       = <<-EOT
    backend "s3" {
      bucket         = "${aws_s3_bucket.tf_state.bucket}"
      key            = "ENVIRONMENT_NAME/terraform.tfstate"   # e.g. dev/terraform.tfstate or prod/terraform.tfstate
      region         = "${var.aws_region}"
      dynamodb_table = "${aws_dynamodb_table.tf_locks.name}"
      encrypt        = true
    }
  EOT
}
