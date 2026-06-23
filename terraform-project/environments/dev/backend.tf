###############################################################################
# REMOTE BACKEND — S3 + DynamoDB
#
# >>> CHANGE the bucket name and dynamodb_table to match what bootstrap/
# created for you (see bootstrap/main.tf output: backend_config_snippet).
#
# This file has NO variables — Terraform backend blocks cannot use variables
# or interpolation, values must be hardcoded literals here.
###############################################################################

terraform {
  backend "s3" {
    bucket         = "gowthamstatefile2026" # <<< CHANGE ME — match bootstrap output
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"                          # <<< CHANGE ME if you used a different region
    dynamodb_table = "tfstatelocks"                  # <<< CHANGE ME — match bootstrap output
    encrypt        = true
  }
}
