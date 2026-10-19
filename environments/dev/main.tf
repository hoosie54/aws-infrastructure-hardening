terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Enterprise Tagging: Tracks ownership and cloud costs
  default_tags {
    tags = {
      Environment = "Development"
      Owner       = "SecOps-Team"
      Project     = "DataProtection"
      CostCenter  = "Engineering-101"
    }
  }
}

# Call our local network security module
module "secure_network" {
  source = "../../modules/network"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}
