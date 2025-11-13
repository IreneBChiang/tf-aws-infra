# 先用一個占位的 zip（第一次可手動上傳到 S3），之後由 serverless repo 的 GitHub Actions update-function-code
# 打包本地 lambda_src 成 zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_src.zip"
}

# Lambda function（直接寫死）
resource "aws_lambda_function" "email" {
  function_name    = "${var.project_name}-lambda-email"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.11"
  handler          = "index.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256
}

# 允許 SNS 觸發 Lambda
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_signup.arn
}

# SNS 訂閱
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.user_signup.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email.arn
}

output "lambda_name" { value = aws_lambda_function.email.function_name }
