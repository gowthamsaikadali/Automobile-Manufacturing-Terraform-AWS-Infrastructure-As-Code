###############################################################################
# IAM MODULE
# Creates an EC2 instance role with least-privilege permissions:
#   - SSM Session Manager access (so you don't even need SSH/bastion)
#   - CloudWatch Logs (app logs)
#   - Read-only access to the one Secrets Manager secret holding DB creds
#   - Optional scoped S3 access if your app needs a bucket
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "ec2_role" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-ec2-role"
    Environment = var.environment
  }
}

# Lets you connect via `aws ssm start-session` instead of opening SSH to the world
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Logs — app/gunicorn/nginx logs shipped centrally
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${local.name_prefix}-cloudwatch-logs"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/${local.name_prefix}/*"
      }
    ]
  })
}

# Read AND write access to JUST the one secret holding DB credentials — not all
# of Secrets Manager. Write is needed because user_data.sh.tpl adds the
# generated app admin password into this same secret after first boot, so you
# can retrieve it via `aws secretsmanager get-secret-value` instead of reading
# instance logs.
resource "aws_iam_role_policy" "secrets_access" {
  name = "${local.name_prefix}-secrets-read-write"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue"]
        Resource = var.secrets_manager_secret_arn
      }
    ]
  })
}
# Optional scoped S3 access — only attached if a bucket ARN is supplied
resource "aws_iam_role_policy" "s3_access" {
  count = var.s3_app_bucket_arn != "" ? 1 : 0
  name  = "${local.name_prefix}-s3-access"
  role  = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [var.s3_app_bucket_arn, "${var.s3_app_bucket_arn}/*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
