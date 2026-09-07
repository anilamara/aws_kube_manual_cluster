# providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# variables.tf
variable "aws_region" {
  default = "ap-south-1"
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair already uploaded to AWS"
  type        = string
  default     = "id_ed25519" 
}
