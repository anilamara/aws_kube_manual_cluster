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

module "networking" {
  source      = "./modules/networking"
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}

module "loadbalancer" {
  source             = "./modules/loadbalancer"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  environment        = var.environment
}

module "compute" {
  source              = "./modules/compute"
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  environment         = var.environment
  ssh_public_key_path = var.ssh_public_key_path
  target_group_arn    = module.loadbalancer.target_group_arn
}
