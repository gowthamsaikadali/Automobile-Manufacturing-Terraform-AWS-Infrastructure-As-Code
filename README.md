## 📌 Project Overview

This project is the **Terraform-automated version** of the manually deployed [Automobile Manufacturing Dashboard](https://github.com/gowthamsaikadali/Automobile-Manufacturing-Dashboard-Manual-2-Tier-AWS-Deployment-EC2-RDS-MySQL-), which was originally set up through the AWS Console.

The goal was to **convert the entire manual AWS infrastructure into Infrastructure as Code (IaC)** using Terraform with a **modular, multi-environment architecture** supporting both `dev` and `prod` environments.

---

## 🏗️ Architecture Overview

```
terraform-project/
├── bootstrap/               # Remote state backend setup (S3 + DynamoDB)
│   └── main.tf
├── environments/
│   ├── dev/                 # Dev environment configuration
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── dev.tfvars
│   └── prod/                # Prod environment configuration
│       ├── main.tf
│       ├── backend.tf
│       ├── provider.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── prod.tfvars
├── modules/
│   ├── network/             # VPC, Subnets, IGW, Route Tables
│   ├── security/            # Security Groups (SG chaining)
│   ├── compute/             # EC2 instances, Key Pair
│   ├── database/            # RDS MySQL in private subnet
│   ├── alb/                 # Application Load Balancer (Multi-AZ)
│   └── iam/                 # IAM Roles and Instance Profiles
├── scripts/                 # Utility scripts
└── .gitignore
```

---

## 🌐 AWS Infrastructure Provisioned

### Networking (VPC Module)
- Custom **VPC** with DNS support enabled
- **Public Subnets** (2 AZs) — for EC2 and ALB
- **Private Subnets** (2 AZs) — for RDS MySQL
- **Internet Gateway** attached to VPC
- **Route Tables** with proper associations

### Security (Security Module)
- **ALB Security Group** — allows HTTP (80) from internet
- **EC2 Security Group** — allows traffic only from ALB SG (SG chaining)
- **RDS Security Group** — allows MySQL (3306) only from EC2 SG
- Zero direct public access to database layer

### Compute (Compute Module)
- **EC2 Instance** running Flask + Gunicorn + Nginx
- Deployed in public subnet with auto-assigned public IP
- User data script for application bootstrapping

### Database (Database Module)
- **RDS MySQL** in private subnet
- **DB Subnet Group** across 2 AZs
- Not publicly accessible
- Automated backups enabled

### Load Balancer (ALB Module)
- **Application Load Balancer** (internet-facing)
- **Target Group** with health checks
- **Listener** on port 80 forwarding to EC2
- Multi-AZ coverage

### IAM (IAM Module)
- **EC2 IAM Role** with SSM access
- **Instance Profile** attached to EC2
- Least-privilege policy principle

---

## 🔧 Tech Stack

| Category | Technology |
|----------|------------|
| IaC Tool | Terraform v1.x |
| Cloud Provider | AWS |
| Compute | EC2 (t2.micro / t3.micro) |
| Database | RDS MySQL 8.0 |
| Load Balancer | AWS ALB |
| Networking | VPC, Subnets, IGW, Route Tables |
| State Backend | S3 + DynamoDB (remote state + locking) |
| Language | HCL (HashiCorp Configuration Language) |
| OS | Ubuntu 22.04 LTS |
| App Stack | Flask + Gunicorn + Nginx |

---

## 🔄 Project Evolution

> This project is a **direct Terraform automation** of the manual AWS setup done previously.

| Phase | Approach | Repo |
|-------|----------|------|
| Phase 1 | Manual AWS Console deployment (VPC, EC2, RDS, ALB) | [Manual Deployment](https://github.com/gowthamsaikadali/Automobile-Manufacturing-Dashboard-Manual-2-Tier-AWS-Deployment-EC2-RDS-MySQL-) |
| Phase 2 | Terraform IaC with modular multi-environment structure | **This Repo** |

---

## 🚀 Getting Started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.x installed
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured
- AWS credentials with appropriate permissions
- S3 bucket and DynamoDB table for remote state (created via bootstrap)

### Step 1: Bootstrap Remote State Backend

```bash
cd bootstrap/
terraform init
terraform apply
```

This creates:
- S3 bucket for Terraform state files
- DynamoDB table for state locking

### Step 2: Deploy Dev Environment

```bash
cd environments/dev/
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

### Step 3: Deploy Prod Environment

```bash
cd environments/prod/
terraform init
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

### Step 4: Destroy (When Done)

```bash
terraform destroy -var-file="dev.tfvars"
```

---

## ⚙️ Environment Configuration

### Dev (`dev.tfvars`)
```hcl
environment    = "dev"
instance_type  = "t2.micro"
db_instance    = "db.t3.micro"
```

### Prod (`prod.tfvars`)
```hcl
environment    = "prod"
instance_type  = "t3.small"
db_instance    = "db.t3.small"
```

---

## 🏛️ Infrastructure Diagram

```
Internet
    │
    ▼
[ALB - Public Subnets - 2 AZs]
    │
    ▼
[EC2 - Flask/Gunicorn/Nginx]  ──────► [IAM Role/SSM]
    │
    ▼
[RDS MySQL - Private Subnets - 2 AZs]

Security Group Flow:
Internet → ALB-SG → EC2-SG → RDS-SG
```

---

## 📊 Terraform State Management

| Resource | Details |
|----------|---------|
| Backend | AWS S3 |
| State Locking | DynamoDB |
| Dev State Key | `dev/terraform.tfstate` |
| Prod State Key | `prod/terraform.tfstate` |

---

## 📁 Module Details

### `modules/network`
Provisions the full VPC setup — CIDR blocks, public/private subnets across 2 AZs, Internet Gateway, and route table associations.

### `modules/security`
Creates all security groups with SG-to-SG chaining (no hardcoded IPs). ALB → EC2 → RDS traffic flow enforced.

### `modules/compute`
Launches EC2 instance in the public subnet with the IAM instance profile and bootstraps the Automobile app via user data.

### `modules/database`
Provisions RDS MySQL in private subnets with a DB subnet group, backup retention, and no public accessibility.

### `modules/alb`
Creates internet-facing ALB, target group with health checks, and HTTP listener forwarding traffic to EC2.

### `modules/iam`
Defines IAM role with EC2 trust policy and SSM managed policy, plus instance profile for attachment.

---

## 🔐 Security Best Practices Followed

- ✅ No hardcoded credentials in code
- ✅ Security Group chaining (no 0.0.0.0/0 to EC2 or RDS)
- ✅ RDS in private subnet — not publicly accessible
- ✅ Remote state with S3 encryption + DynamoDB locking
- ✅ `.tfstate` files excluded via `.gitignore`
- ✅ `*.tfvars` with sensitive values not committed
- ✅ IAM least-privilege principle applied

---


| Resource | Screenshot |
|----------|------------|
| VPC & Subnets | *(coming soon)* |
| EC2 Instance | *(coming soon)* |
| RDS MySQL | *(coming soon)* |
| ALB Target Group | *(coming soon)* |
| App Running | *(coming soon)* |

---

## 🧠 Key Learnings

- Converted a fully manual AWS deployment into **reusable Terraform modules**
- Implemented **multi-environment IaC** (dev/prod) with separate state files
- Applied **Security Group chaining** as code instead of manual SG rules
- Understood **remote state management** with S3 backend and DynamoDB locking
- Practiced **Terraform module structure** for production-grade infrastructure

---

## 👤 Author

**Gowtham Sai Kadali**
- 🐙 GitHub:https://github.com/gowthamsaikadali
- 📧 Email: gowthamkadali2510@gmail.com
- 📍 Hyderabad, India
