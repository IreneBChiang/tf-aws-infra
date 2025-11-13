# --- EC2 AssumeRole policy ---
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# --- IAM Role for EC2 ---
resource "aws_iam_role" "app_role" {
  name               = "a06-ec2-s3-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# --- Least-privilege S3 access for the app bucket ---
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.images.arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.images.arn]
  }
}

resource "aws_iam_policy" "s3_access" {
  name   = "a06-ec2-s3-access"
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# --- Instance Profile to attach on EC2 ---
resource "aws_iam_instance_profile" "app_profile" {
  name = "a06-ec2-profile"
  role = aws_iam_role.app_role.name
}

resource "aws_iam_role_policy_attachment" "cwagent_server" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cw_logs_full" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# 讓 EC2：讀取 DB 密碼的 Secret、用對的 KMS 解密、發 SNS
data "aws_iam_policy_document" "ec2_secret_kms_sns" {
  statement {
    sid       = "ReadDBSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.db.arn]
  }

  statement {
    sid       = "DecryptSecret"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.sec.arn]

    # （推薦）限制必須是經由 Secrets Manager 解密
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid       = "PublishSignupEvent"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.user_signup.arn]
  }
}

resource "aws_iam_policy" "ec2_secret_kms_sns" {
  name   = "${var.project_name}-ec2-secret-kms-sns"
  policy = data.aws_iam_policy_document.ec2_secret_kms_sns.json
}

resource "aws_iam_role_policy_attachment" "ec2_secret_kms_sns_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.ec2_secret_kms_sns.arn
}
