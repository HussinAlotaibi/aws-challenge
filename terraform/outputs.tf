output "cloudfront_url" {
  description = "Application URL via CloudFront"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "alb_dns" {
  description = "ALB DNS name (access via CloudFront only)"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "s3_bucket" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.bucket
}

output "codedeploy_app" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.main.name
}

output "github_actions_role_arn" {
  description = "Paste this into GitHub Actions secret AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "secret_name" {
  description = "Secrets Manager secret name for RDS credentials"
  value       = aws_secretsmanager_secret.rds.name
}
