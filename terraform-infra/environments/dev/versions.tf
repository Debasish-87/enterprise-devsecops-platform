terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "409837635702-devsecops-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "enterprise-devsecops"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "ap-south-1"
}
