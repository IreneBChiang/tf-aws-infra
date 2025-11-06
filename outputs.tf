# VPC / Subnets
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs for the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs for the private subnets."
  value       = aws_subnet.private[*].id
}

# FQDN for this environment (dev/demo)
output "fqdn" {
  value = "${var.env}.${var.root_domain}"
}

# ALB info (主要用這兩個驗證)
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.app.dns_name
}

output "app_url_via_alb" {
  description = "Convenient HTTP URL through ALB."
  value       = "http://${aws_lb.app.dns_name}"
}

output "app_url_via_domain" {
  description = "Convenient HTTP URL through Route53 alias."
  value       = "http://${var.env}.${var.root_domain}"
}

# 單機 EC2 的 Public IP（只有在 enable_single_instance = true 時才會有值）
# 注意：這裡用 length(...) 判斷，避免 count=0 時取值炸掉
# output "app_public_ip" {
#   description = "Public IP of the single EC2 instance (present only when enable_single_instance = true)."
#   value       = length(aws_instance.csye6225_app) > 0 ? aws_instance.csye6225_app[0].public_ip : null
# }
