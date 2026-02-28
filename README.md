# Deployment Application CI/CD with AWS

Terraform infrastructure for deploying a containerized application on AWS with a CI/CD flow triggered from Bitbucket.

## Architecture

- VPC with 2 public subnets (ALB) and 2 private subnets (EC2 + RDS)
- Internet Gateway and optional NAT Gateway
- Application Load Balancer + target group + health checks
- Auto Scaling Group (Amazon Linux 2023 EC2 instances)
- RDS MySQL (Single-AZ, private)
- ECR repository for container images
- S3 artifact bucket (versioning + SSE)
- CodeBuild project (source: Bitbucket via CodeConnections)
- CodeDeploy application/deployment group (in-place deployment to ASG)
- API Gateway + Lambda webhook endpoint to trigger CodeBuild
- SNS email alerts + CloudWatch alarms

## Repository Structure

```text
.
├── bootstrap/   # Creates Terraform backend resources (S3 + DynamoDB)
└── main/        # Main infrastructure: network, compute, DB, CI/CD, monitoring
```

## Prerequisites

- Terraform `>= 1.5`
- AWS account + IAM permissions to create all resources
- AWS CLI configured (`aws configure`)
- Bitbucket repository for application source code
- AWS CodeConnections connection to Bitbucket

## Configuration

1. Use the example file:

```bash
cp main/terraform.tfvars.example main/terraform.tfvars
```

2. Fill required values in `main/terraform.tfvars`:

- `bitbucket_repo_url`
- `bitbucket_branch`
- `codestar_connection_arn`
- `alert_email`

3. Optional overrides:

- `db_password` (otherwise deterministic generated password is used)
- `webhook_secret` (otherwise deterministic generated secret is used)

## Deploy

1. Bootstrap backend resources:

```bash
cd bootstrap
terraform init
terraform apply
```

2. Verify `main/backend.tf` points to your bootstrap S3 backend bucket/key.

3. Deploy main stack:

```bash
cd ../main
terraform init -reconfigure
terraform plan
terraform apply
```

4. Confirm SNS email subscription from inbox.

5. After apply, get webhook URL from output `bitbucket_webhook_url` and configure Bitbucket webhook.

## Notes

- This repository provisions infrastructure. Your application source/buildspec is expected in the Bitbucket repo (`cicd/buildspec.yml` path in CodeBuild config).
- EC2 instances are private; access is intended via AWS SSM.
- NAT can be disabled using `enable_nat = false` to reduce cost (with trade-offs for outbound private subnet access).

## Cleanup

```bash
cd main && terraform destroy
cd ../bootstrap && terraform destroy
```
