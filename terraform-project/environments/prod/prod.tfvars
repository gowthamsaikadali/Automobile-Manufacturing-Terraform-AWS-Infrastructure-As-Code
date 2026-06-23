###############################################################################
# PROD ENVIRONMENT VALUES
# Run from environments/prod/ with:
#   terraform apply -var-file="prod.tfvars"
###############################################################################

aws_region   = "ap-south-1"
project_name = "forgepoint"
environment  = "prod"

# --- Networking ---
vpc_cidr                 = "10.1.0.0/16"   # different range than dev, in case you ever peer them
azs                       = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs      = ["10.1.0.0/24", "10.1.1.0/24"]
private_app_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
private_db_subnet_cidrs  = ["10.1.20.0/24", "10.1.21.0/24"]
enable_nat_gateway        = true

# --- Security ---
# <<< CHANGE ME: restrict to your office/VPN IP, never leave open in prod
ssh_allowed_cidr = "203.0.113.45/32"

# --- Compute ---
instance_type = "t3.small" # bump up from dev's t3.micro for real traffic
# <<< CHANGE ME: create a SEPARATE key pair for prod, don't reuse dev's
key_pair_name = "forgepoint-prod-key"
app_port      = 8000

# <<< CHANGE ME: your repo URL — typically pin prod to a tagged release branch
git_repo_url = "https://github.com/gowthamsaikadali/Automobile-Manufacturing-Application.git"
git_branch   = "main" # consider a stable "release" branch/tag for prod instead of main

min_size         = 2 # prod should never run on a single instance
max_size          = 4
desired_capacity  = 2

# --- Database ---
db_engine         = "mysql"
db_engine_version = "8.0.36"
db_instance_class = "db.t3.small" # bump up from dev's db.t3.micro
db_name           = "forgepoint"
db_username       = "forgepoint_admin"
# db_password: still left blank to auto-generate; or set via:
#   export TF_VAR_db_password='YourStrongProdPassword!'

# --- ALB / TLS ---
# <<< CHANGE ME: for real prod, get an ACM cert (free) for your domain and put the ARN here
certificate_arn   = ""
health_check_path = "/health"
