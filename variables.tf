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

variable "db_password" {
  type        = string
  sensitive   = true
  description = "強密碼，請放在 terraform.tfvars"
}

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