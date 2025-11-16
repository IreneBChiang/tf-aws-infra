resource "aws_kms_key" "ec2" {
  description         = "EC2 CMK"
  enable_key_rotation = true
}

resource "aws_kms_alias" "ec2_alias" {
  name          = "alias/${var.project_name}-ec2"
  target_key_id = aws_kms_key.ec2.key_id
}

resource "aws_kms_key" "rds" {
  description         = "RDS CMK"
  enable_key_rotation = true
}

resource "aws_kms_key" "s3" {
  description         = "S3 CMK"
  enable_key_rotation = true
}

resource "aws_kms_key" "sec" {
  description         = "Secrets CMK"
  enable_key_rotation = true
}
