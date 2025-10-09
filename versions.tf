terraform {
  # Sets the minimum required Terraform CLI version
  required_version = ">= 1.0.0"

  required_providers {
    # Specifies the AWS provider and source
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a compatible version for the latest features
    }
  }
}

# Configures the AWS provider. The region will be determined by the
# variable or the CLI profile when running 'terraform apply'.
provider "aws" {
  # Explicitly defined in main.tf if using a region variable, otherwise relies on CLI config like --profile dev
}