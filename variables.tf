variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "csye6225" # 僅用於 Tag 顯示
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 3
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "app_ami_id" {
  type        = string
  description = "Packer 產出的 AMI ID"
}

# RDS 相關
variable "db_username" {
  type    = string
  default = "csye6225"
}

# variable "db_password" {
#   type        = string
#   sensitive   = true
#   description = "強密碼，請放在 terraform.tfvars"
# }

variable "db_name" {
  type    = string
  default = "csye6225"
}

# variable "aws_profile" {
#   type        = string
#   description = "AWS profile to use (e.g., dev or demo)"
# }

# 用哪個系統帳號跑 service（A05 要求用 csye6225）
variable "service_user" {
  type    = string
  default = "csye6225"
}

# Assignment07 新增項目
# Root Domain
variable "root_domain" {
  description = "Root domain managed in Route53 (root account)"
  type        = string
  default     = "ibchiang.me"
}

# Environment (dev or demo)
variable "env" {
  description = "Environment subdomain: dev or demo"
  type        = string
}

# CloudWatch Log Group 名稱（依環境可分開）
variable "log_group_name" {
  description = "CloudWatch Log Group name for this environment"
  type        = string
  default     = "/csye6225/webapp"
}

# CloudWatch Agent 設定用（不一定要在 tfvars 設）
variable "cwagent_config_json" {
  description = "Rendered CloudWatch Agent config template"
  type        = string
  default     = ""
}

#（可選）Metrics 前綴（CloudWatch/StatsD）
variable "metrics_prefix" {
  description = "Prefix for StatsD metrics (e.g., webapp.dev)"
  type        = string
  default     = "webapp"
}

# 空字串表示「不用 SSH 金鑰」
variable "key_name" {
  type    = string
  default = ""
}

variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}

# 控制是否建立單台 EC2（舊作業用）
variable "enable_single_instance" {
  type    = bool
  default = false
}

# A09 新增項目

# ---- For Secrets Manager ----
# Terraform 建 secret 時會用這個 region 與 ARN 傳入 userdata
variable "db_secret_arn" {
  description = "ARN of the DB password secret in Secrets Manager"
  type        = string
  default     = ""
}

# ---- For SNS / Lambda ----
variable "user_signup_topic_arn" {
  description = "SNS topic ARN for user signup notifications"
  type        = string
  default     = ""
}

# ---- For KMS ----
variable "kms_key_alias" {
  description = "Alias name for KMS key used to encrypt resources"
  type        = string
  default     = "alias/csye6225-key"
}

# ---- For ACM & Domain ----
# domain 用來掛 HTTPS 憑證（dev 用 ACM, demo 匯入）
variable "app_domain" {
  description = "Full domain name of the web application (e.g., dev.ibchiang.me)"
  type        = string
  default     = ""
}

variable "dev_domain" {
  description = "Domain name used for dev environment"
  type        = string
  default     = ""
}

variable "demo_domain" {
  description = "Domain name used for demo environment"
  type        = string
  default     = ""
}

# ---- For Lambda Artifact (from GitHub Actions) ----
variable "lambda_artifact_s3_bucket" {
  description = "S3 bucket storing Lambda deployment zip (uploaded by CI/CD)"
  type        = string
  default     = ""
}

variable "lambda_artifact_s3_key" {
  description = "Object key (path) for Lambda zip inside the bucket"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "Imported ACM certificate arn for demo ALB HTTPS"
  type        = string
  default     = ""
}

variable "verify_base_url" {
  description = "Base URL for email verification link"
  type        = string
}

variable "from_email" {
  description = "From email address for verification emails"
  type        = string
}
