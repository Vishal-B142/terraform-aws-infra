# terraform-aws-infra

> Reusable Terraform modules for AWS infrastructure — ECR repositories, ECS Fargate pipelines (current), and EKS cluster provisioning (planned). Used alongside Jenkins CI/CD for automated deployments.

---

## Stack

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazonaws&logoColor=white)

---

## Current vs Planned

| Module | Status | Purpose |
|---|---|---|
| `ecr/` | ✅ Active | Container registry per service |
| `ecs-fargate/` | ✅ Active | ECS Fargate + ALB + CloudWatch (legacy, pre-k3s) |
| `iam/` | ✅ Active | Task execution roles, ECR pull policies |
| `eks/` | 🔄 Planned | EKS cluster + node groups (see [eks-production](https://github.com/Vishal-B142/eks-production)) |
| `vpc/` | 🔄 Planned | VPC + subnets for EKS |
| `acm/` | 🔄 Planned | ACM wildcard cert for EKS ALB |

---

## Repo Structure

```
terraform-aws-infra/
├── modules/
│   ├── ecr/
│   │   ├── main.tf           # ECR repo per service
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecs-fargate/
│   │   ├── main.tf           # ECS cluster + Fargate service + ALB
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/
│   │   ├── main.tf           # Task execution role + ECR pull policy
│   │   └── variables.tf
│   ├── eks/                  # 🔄 Planned
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vpc/                  # 🔄 Planned
│       ├── main.tf
│       └── variables.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       └── terraform.tfvars
├── backend.tf                # S3 remote state + DynamoDB locking
└── README.md
```

---

## Remote State

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

---

## Modules

### ECR — Container Registry

```hcl
module "ecr" {
  source         = "../../modules/ecr"
  repository_name = "gateway-service"
  region          = "ap-south-1"
  lifecycle_policy = {
    keep_tagged   = 10    # Keep last 10 tagged images
    remove_untagged = true
  }
}
```

### ECS Fargate (current production setup)

```hcl
module "ecs" {
  source         = "../../modules/ecs-fargate"
  cluster_name   = "prod-cluster"
  service_name   = "gateway-service"
  image          = "<ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/gateway-service:latest"
  cpu            = 512
  memory         = 1024
  desired_count  = 2
  container_port = 8007
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnets
  alb_arn        = module.alb.arn
}
```

### IAM — Task Execution Role

```hcl
module "iam" {
  source       = "../../modules/iam"
  role_name    = "ecs-task-execution-role"
  ecr_registry = "<ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com"
}
```

### EKS — Planned

```hcl
# modules/eks/main.tf (planned — mirrors eks-production runbook)
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "prod-cluster"
  cluster_version = "1.29"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  eks_managed_node_groups = {
    prod-apps = {
      instance_types = ["t3.large"]
      min_size       = 2
      max_size       = 6
      desired_size   = 2
    }
    prod-monitoring = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }
  }
}
```

---

## Usage

```bash
# Initialise with remote backend
cd environments/prod
terraform init

# Plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"
```

---

## CloudWatch Integration (ECS Fargate)

Centralised logging and alerting set up for all ECS Fargate services:

```hcl
# Log group per service
resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 30
}

# CPU alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.service_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
}
```

---

## Related

- [eks-production](https://github.com/Vishal-B142/eks-production) — EKS migration using the `eks/` module
- [jenkins-k8s-pipeline](https://github.com/Vishal-B142/jenkins-k8s-pipeline) — CI/CD that deploys to infrastructure provisioned here
- [observability-stack](https://github.com/Vishal-B142/observability-stack) — monitoring stack
