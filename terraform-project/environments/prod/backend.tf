terraform {
  backend "s3" {
    bucket         = "forgepoint-tfstate-CHANGE-ME-12345" # <<< CHANGE ME — same bucket as dev, different key
    key            = "prod/terraform.tfstate"               # <<< note: different key than dev
    region         = "ap-south-1"                            # <<< CHANGE ME if different region
    dynamodb_table = "forgepoint-tf-locks"                    # <<< CHANGE ME — match bootstrap output
    encrypt        = true
  }
}
