###############################################################################
# SECURITY MODULE
# Three security groups, chained for least privilege:
#   alb_sg  : Internet -> ALB on 80/443
#   app_sg  : ALB only  -> EC2 on app_port (8000)    + you -> EC2 on 22
#   db_sg   : EC2 only  -> RDS on db_port (3306/5432)
# Nothing reaches RDS or the app instances directly from the internet.
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# ALB Security Group — internet-facing, ports 80 + 443
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow HTTP/HTTPS from the internet to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "ALB can reach anything (needed to reach app instances)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-alb-sg"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Application (EC2) Security Group
#   - app_port inbound ONLY from the ALB security group (not the whole internet)
#   - SSH (22) inbound ONLY from var.ssh_allowed_cidr
# ---------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Allow app traffic from ALB only, and SSH from trusted CIDR"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH from trusted CIDR only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "App instances can reach anything (pip installs, RDS, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-app-sg"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Database (RDS) Security Group
#   - db_port inbound ONLY from the app security group
#   - no internet egress needed
# ---------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "Allow DB traffic from app instances only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB port from app instances only"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow outbound (patching, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-db-sg"
    Environment = var.environment
  }
}
