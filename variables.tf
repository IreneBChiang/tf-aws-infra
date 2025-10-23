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

variable "aws_profile" {
  type        = string
  description = "AWS profile to use (e.g., dev or demo)"
}

# 用哪個系統帳號跑 service（A05 要求用 csye6225）
variable "service_user" {
  type    = string
  default = "csye6225"
}
