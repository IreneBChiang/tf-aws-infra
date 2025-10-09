// Output the VPC ID for easy reference
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

// Output the list of Public Subnet IDs
output "public_subnet_ids" {
  description = "List of IDs for the public subnets."
  value       = aws_subnet.public[*].id
}

// Output the list of Private Subnet IDs
output "private_subnet_ids" {
  description = "List of IDs for the private subnets."
  value       = aws_subnet.private[*].id
}