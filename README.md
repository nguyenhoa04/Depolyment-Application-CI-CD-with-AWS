# Deployment Application CI/CD with AWS

This repository contains both:

- Infrastructure as Code (Terraform) for AWS deployment and CI/CD
- Application source code (`vproapp`) used by the pipeline

## What is Provisioned

- VPC with 2 public subnets and 2 private subnets
- Internet Gateway and optional NAT Gateway
- ALB, target group, and listener
- Auto Scaling Group for EC2 app instances
- RDS MySQL (private, single-AZ)
- ECR repository for container images
- S3 artifact bucket (versioning + encryption)
- CodeBuild + CodeDeploy integration
- API Gateway + Lambda webhook trigger
- SNS email alerts + CloudWatch alarms

## Repository Structure

```text
.
├── bootstrap/      # Terraform backend bootstrap (S3 state + DynamoDB lock table)
├── main/           # Main Terraform stack (network, compute, database, CICD, monitoring)
└── vproapp/        # Java application source and CICD assets (buildspec, appspec, scripts)
```

## Prerequisites

- Terraform `>= 1.5`
- AWS CLI configured with an account that can create required resources
- AWS CodeConnections connection to Bitbucket
- Bitbucket repository URL/branch for CodeBuild source

## Configure Terraform Variables

Create tfvars from example:

```bash
cp main/terraform.tfvars.example main/terraform.tfvars
```

Set required values in `main/terraform.tfvars`:

- `bitbucket_repo_url`
- `bitbucket_branch`
- `codestar_connection_arn`
- `alert_email`

Optional:

- `db_password`
- `webhook_secret`

## Deploy Infrastructure

1. Bootstrap backend:

```bash
cd bootstrap
terraform init
terraform apply
```

2. Confirm `main/backend.tf` matches your backend bucket/key.

3. Deploy main stack:

```bash
cd ../main
terraform init -reconfigure
terraform plan
terraform apply
```

4. Confirm SNS email subscription.
5. Use output `bitbucket_webhook_url` in your Bitbucket webhook settings.

## CI/CD Flow

1. Bitbucket push event calls API Gateway webhook
2. Lambda validates HMAC signature and starts CodeBuild
3. CodeBuild builds/publishes image, creates deployment artifact
4. CodeDeploy deploys to EC2 Auto Scaling Group instances
5. ALB routes traffic to healthy targets

## Notes

- `vproapp/` is included in this repository, but current CodeBuild config uses Bitbucket as source.
- EC2 instances are in private subnets; manage via AWS SSM.
- NAT can be disabled (`enable_nat = false`) to reduce cost.

## Destroy

```bash
cd main && terraform destroy
cd ../bootstrap && terraform destroy
```
