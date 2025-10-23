resource "random_uuid" "bkt" {}

# Bucket（UUID 名稱）
resource "aws_s3_bucket" "images" {
  bucket        = random_uuid.bkt.result
  force_destroy = true
  tags          = { Name = "a06-images" }
}

# 擁有權設定（避免 ACL 衝突）
resource "aws_s3_bucket_ownership_controls" "own" {
  bucket = aws_s3_bucket.images.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# 私有 ACL
resource "aws_s3_bucket_acl" "acl" {
  depends_on = [aws_s3_bucket_ownership_controls.own]
  bucket     = aws_s3_bucket.images.id
  acl        = "private"
}

# 伺服端加密（AES256）
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 30 天轉 STANDARD_IA
resource "aws_s3_bucket_lifecycle_configuration" "lc" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "to-ia-30d"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.images.bucket
  description = "UUID-named S3 bucket"
}
