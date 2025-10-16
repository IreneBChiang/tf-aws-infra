# set variables

# A unique prefix for all resources (key for multiple deployments without conflict)
variable "project_name" {
  description = "A unique prefix (e.g., your-name-dev) for all created resources to ensure no conflicts."
  type        = string
}

# The AWS region
variable "region" {
  description = "The AWS region to deploy resources in (e.g., us-east-1)."
  type        = string
  default     = "us-east-1"
}

# The main IP address scope for the VPC
variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# The required number of Availability Zones (AZs) -> 3
variable "az_count" {
  description = "The number of Availability Zones to use. Must be 3 as per assignment."
  type        = number
  default     = 3
}

# Classless Inter-Domain Routing(CIDR) blocks for the 3 public subnets
variable "public_cidrs" {
  description = "List of CIDR blocks for the 3 public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# CIDR blocks for the 3 private subnets
variable "private_cidrs" {
  description = "List of CIDR blocks for the 3 private subnets."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

# AMI to launch the app EC2 with (built by Packer in the webapp repo)
variable "app_ami_id" {
  description = "Packer-built AMI ID for the application instance (from DEV account)"
  type        = string
}

# Port your app listens on (FastAPI default 8080)
variable "app_port" {
  description = "Application listening port"
  type        = number
  default     = 8080
}