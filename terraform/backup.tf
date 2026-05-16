resource "aws_backup_vault" "main" {
  name = "${var.project_name}-vault"
}

resource "aws_backup_plan" "main" {
  name = "${var.project_name}-plan"

  rule {
    rule_name         = "daily-7day-retention"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 * * ? *)"

    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_selection" "rds" {
  name         = "${var.project_name}-rds"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn
  resources    = [aws_db_instance.main.arn]
}
