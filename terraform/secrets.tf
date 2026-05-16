resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "rds" {
  name                    = "${var.project_name}/rds-credentials"
  recovery_window_in_days = 0
  tags                    = { Name = "${var.project_name}-rds-secret" }
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    engine   = "mysql"
    host     = aws_db_instance.main.address
    port     = 3306
    dbname   = "appdb"
  })
}
