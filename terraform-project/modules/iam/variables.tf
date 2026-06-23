variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials, so EC2 can read it. Pass empty string to skip this policy statement."
  type        = string
}

variable "s3_app_bucket_arn" {
  description = "Optional: ARN of an S3 bucket the app needs to read/write (e.g. for file uploads/reports). Leave empty if unused."
  type        = string
   default     = ""
}
