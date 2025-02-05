terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  # Account-ID is hidden for project security
  backend "s3" {
    bucket         = "${var.account_id}-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "${var.account_id}-terraform-state-lock-table"
  }
}

provider "aws" {
  region = "us-east-1"
}
