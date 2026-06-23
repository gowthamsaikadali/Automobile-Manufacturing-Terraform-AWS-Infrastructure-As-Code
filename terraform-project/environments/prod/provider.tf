###############################################################################
# PROVIDER CONFIGURATION
# >>> THIS IS WHERE YOUR AWS PROVIDER INFO GOES <<<
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # --------------------------------------------------------------------
  # CREDENTIALS — pick ONE of the following approaches. Do not hardcode
  # access keys in this file or commit them to git, ever.
  # --------------------------------------------------------------------

  # OPTION A (recommended for local use): use your AWS CLI named profile.
  # Run `aws configure --profile myprofile` once, then uncomment:
  # profile = "myprofile"

  # OPTION B (default): leave this block as-is and instead export
  # standard environment variables before running terraform:
  #   export AWS_ACCESS_KEY_ID="..."
  #   export AWS_SECRET_ACCESS_KEY="..."
  #   export AWS_SESSION_TOKEN="..."   (only if using temporary/SSO creds)
  # Terraform's AWS provider picks these up automatically — nothing to
  # change in code.

  # OPTION C (CI/CD, e.g. GitHub Actions with OIDC): assume a role instead.
  # assume_role {
  #   role_arn = "arn:aws:iam::123456789012:role/github-actions-deploy-role"
  # }

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
