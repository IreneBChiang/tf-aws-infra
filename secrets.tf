resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name       = "irenebc-password-v8"
  kms_key_id = aws_kms_key.sec.id
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    password = random_password.db.result
  })
}

output "db_secret_arn" { value = aws_secretsmanager_secret.db.arn }

# 給 SendGrid API Key 用的 Secret
resource "aws_secretsmanager_secret" "email" {
  name       = "irenebc-email-api-key-v2"
  kms_key_id = aws_kms_key.sec.arn
}

# 初始化內容（之後可以去 console 把值改成真正的 API key）
resource "aws_secretsmanager_secret_version" "email" {
  secret_id = aws_secretsmanager_secret.email.id
  secret_string = jsonencode({
    SENDGRID_API_KEY = "REPLACE_WITH_REAL_KEY"
  })
}

output "email_secret_arn" {
  value = aws_secretsmanager_secret.email.arn
}