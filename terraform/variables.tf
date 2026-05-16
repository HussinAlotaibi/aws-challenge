variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "aws-challenge"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "django_admin"
}

variable "alert_email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo in format owner/repo — used for OIDC trust policy"
  type        = string
}
