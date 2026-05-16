# AWS Scalable Web Application

A production-grade scalable web application deployed on AWS using Terraform and automated via GitHub Actions + AWS CodeDeploy.

---

## Architecture

![Architecture Diagram](docs/architecture.png)

| Layer | Service |
|---|---|
| CDN + Edge | CloudFront (2 origins: ALB + S3) |
| Compute | EC2 t2.micro in Auto Scaling Group |
| Load Balancer | Application Load Balancer (CloudFront IPs only) |
| Database | RDS MySQL t3.micro (private subnet) |
| Storage | S3 (static assets + deployment artifacts) |
| Secrets | Secrets Manager (RDS credentials via IAM role) |
| Networking | VPC, public + private subnets, NAT Gateway |
| Monitoring | CloudWatch dashboard + alarms + SNS email alerts |
| Audit | CloudTrail |
| Backup | AWS Backup (daily RDS snapshots, 7-day retention) |
| CI/CD | GitHub Actions → S3 → CodeDeploy (rolling deploy) |
| IaC | Terraform with S3 backend + DynamoDB state locking |

---

## Security Highlights

- ALB security group restricted to **CloudFront managed prefix list** only — not accessible directly from internet
- EC2 in **private subnet** — no public IP, no SSH, access via SSM Session Manager
- RDS in **private subnet** — only accepts MySQL from EC2 security group
- RDS credentials stored in **Secrets Manager**, fetched at runtime via IAM instance profile
- GitHub Actions uses **OIDC** — no long-lived AWS access keys stored anywhere
- All S3 buckets have public access blocked, encrypted at rest

---

## Project Structure

```
├── terraform/          # All infrastructure as code
├── bootstrap/          # S3 + DynamoDB for Terraform state (run first)
├── app/                # Django application
├── scripts/            # CodeDeploy lifecycle hooks
├── appspec.yml         # CodeDeploy deployment spec
└── .github/workflows/  # GitHub Actions CI/CD pipeline
```

---

## Deploy

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform >= 1.5.0
- GitHub repo created

### 1. Bootstrap state backend
```bash
cd bootstrap/
terraform init
terraform apply
# note the bucket name from output
```

### 2. Update backend config
Edit `terraform/main.tf` and update the backend bucket name to match bootstrap output.

### 3. Deploy infrastructure
```bash
cd terraform/
# update terraform.tfvars with your github_repo
terraform init
terraform apply
```

### 4. Add GitHub secrets
After apply, copy the outputs and add to GitHub repo secrets:

| Secret | Terraform Output |
|---|---|
| `AWS_ROLE_ARN` | `github_actions_role_arn` |
| `S3_BUCKET` | `s3_bucket` |

### 5. Deploy app
```bash
git push origin main
# GitHub Actions uploads artifact to S3
# CodeDeploy rolls out to EC2 ASG automatically
```

---

## CI/CD Pipeline

```
git push → GitHub Actions (OIDC auth)
              → zip app
              → upload to S3
              → trigger CodeDeploy
                    → rolling deploy to ASG (one instance at a time)
                    → auto rollback on failure
```

---

## Monitoring

CloudWatch dashboard includes:
- EC2 CPU utilization
- ALB request count
- ALB 5XX error rate
- RDS CPU + free storage

SNS email alerts fire when CPU > 80% or ALB 5XX errors spike.
