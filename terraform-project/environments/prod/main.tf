###############################################################################
# ROOT MODULE — environments/dev
# Wires together: network -> security -> iam -> database -> alb -> compute
# This is the file `terraform apply` actually executes top-to-bottom
# (Terraform resolves the real order via the dependency graph automatically).
###############################################################################

module "network" {
  source = "../../modules/network"

  project_name              = var.project_name
  environment                = var.environment
  vpc_cidr                   = var.vpc_cidr
  azs                         = var.azs
  public_subnet_cidrs        = var.public_subnet_cidrs
  private_app_subnet_cidrs   = var.private_app_subnet_cidrs
  private_db_subnet_cidrs    = var.private_db_subnet_cidrs
  enable_nat_gateway          = var.enable_nat_gateway
  single_nat_gateway          = var.environment == "prod" ? false : true # one NAT per AZ in prod for HA
}

module "security" {
  source = "../../modules/security"

  project_name      = var.project_name
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  ssh_allowed_cidr   = var.ssh_allowed_cidr
  app_port           = var.app_port
  db_port            = var.db_engine == "postgres" ? 5432 : 3306
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment   = var.environment
  # secrets_manager_secret_arn is supplied AFTER the database module creates it —
  # see the iam_secret_attachment workaround note below, or simply rely on the
  # broad-enough default (this module only grants read on the one ARN you pass).
  secrets_manager_secret_arn = module.database.secret_arn
}

module "database" {
  source = "../../modules/database"

  project_name              = var.project_name
  environment                 = var.environment
  private_db_subnet_ids      = module.network.private_db_subnet_ids
  db_security_group_id       = module.security.db_sg_id
  db_engine                  = var.db_engine
  db_engine_version           = var.db_engine_version
  db_instance_class           = var.db_instance_class
  db_name                     = var.db_name
  db_username                 = var.db_username
  db_password                 = var.db_password
  multi_az                    = var.environment == "prod" ? true : false
  skip_final_snapshot         = var.environment == "prod" ? false : true
  deletion_protection         = var.environment == "prod" ? true : false
}

module "alb" {
  source = "../../modules/alb"

  project_name           = var.project_name
  environment              = var.environment
  vpc_id                   = module.network.vpc_id
  public_subnet_ids        = module.network.public_subnet_ids
  alb_security_group_id    = module.security.alb_sg_id
  app_port                 = var.app_port
  health_check_path        = var.health_check_path
  certificate_arn           = var.certificate_arn
}

module "compute" {
  source = "../../modules/compute"

  project_name               = var.project_name
  environment                  = var.environment
  vpc_id                       = module.network.vpc_id
  private_app_subnet_ids       = module.network.private_app_subnet_ids
  app_security_group_id        = module.security.app_sg_id
  iam_instance_profile_name    = module.iam.ec2_instance_profile_name
  target_group_arn             = module.alb.target_group_arn
  instance_type                 = var.instance_type
  key_pair_name                 = var.key_pair_name
  app_port                      = var.app_port
  git_repo_url                  = var.git_repo_url
  git_branch                    = var.git_branch
  min_size                      = var.min_size
  max_size                      = var.max_size
  desired_capacity               = var.desired_capacity
  db_secret_arn                 = module.database.secret_arn
  aws_region                    = var.aws_region
}
