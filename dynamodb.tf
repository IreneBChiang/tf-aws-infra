resource "aws_dynamodb_table" "verification" {
  name         = "${var.project_name}-verification-email"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "email"

  attribute {
    name = "email"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-verification-email"
    Environment = var.env
  }
}
