resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name       = "irenebc-password-v3"
  kms_key_id = aws_kms_key.sec.id
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    password = random_password.db.result
  })
}

output "db_secret_arn" { value = aws_secretsmanager_secret.db.arn }
