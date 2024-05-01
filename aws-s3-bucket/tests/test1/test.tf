terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

module "aws_s3_bucket_static" {
  source         = "../../"
  luther_project = "project"
  luther_env     = "env"
  component      = "static"

  lifecycle_rules = [
    {
      id              = "test"
      enabled         = true
      expiration_days = 3
    }
  ]

  providers = {
    aws    = aws
    random = random
  }
}
