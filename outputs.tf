# Output the VPC ID for easy reference, the value is the vpc id
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

# Output the list of Public Subnet IDs
output "public_subnet_ids" {
  description = "List of IDs for the public subnets."
  value       = aws_subnet.public[*].id
}

# Output the list of Private Subnet IDs
output "private_subnet_ids" {
  description = "List of IDs for the private subnets."
  value       = aws_subnet.private[*].id
}

output "fqdn" {
  value = "${var.env}.${var.root_domain}"
}

output "app_public_ip" {
  value = aws_instance.csye6225_app.public_ip
}
