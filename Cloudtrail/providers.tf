################################################################################
# Terraform
################################################################################
terraform {
  backend "s3" {
    bucket = "balanced-brief-terraform-state"
    key    = "cloudtrail.tfstate"
    region = "us-west-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.32.1"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}
