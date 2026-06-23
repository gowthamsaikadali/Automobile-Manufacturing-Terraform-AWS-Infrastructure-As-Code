###############################################################################
# DEV ENVIRONMENT VALUES
# Run from environments/dev/ with:
#   terraform apply -var-file="dev.tfvars"
###############################################################################

aws_region   = "ap-south-1"
project_name = "automobile-project"
environment  = "dev"

# --- Networking ---
vpc_cidr                 = "10.0.0.0/16"
azs                       = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs      = ["10.0.0.0/24", "10.0.1.0/24"]
private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
private_db_subnet_cidrs  = ["10.0.20.0/24", "10.0.21.0/24"]
enable_nat_gateway        = true

# --- Security ---
# <<< CHANGE ME: replace with your real IP. Find it with: curl ifconfig.me
ssh_allowed_cidr = "0.0.0.0/0"

# --- Compute ---
instance_type = "t3.micro"
# <<< CHANGE ME: must already exist — aws ec2 create-key-pair --key-name automobile-dev-key --region ap-south-1
key_pair_name = "automobile-app-dev-key"
app_port      = 8000

# <<< CHANGE ME: your actual repo URL containing automobile-manufacturing-app/
git_repo_url = "https://github.com/gowthamsaikadali/Automobile-Manufacturing-Application.git"
git_branch   = "main"

min_size         = 1
max_size         = 2
desired_capacity = 1

# --- Database ---
db_engine         = "mysql"
db_engine_version = "8.4.8"
db_instance_class = "db.t3.micro"
backup_retention_days = 1
db_name           = "automobilemanufacturing"
db_username       = "admin"
db_password       = "Admin123"

# --- ALB / TLS ---
certificate_arn    = "" # leave blank for HTTP-only dev ALB
health_check_path  = "/health"
