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
  alias = "us-east-1"
}

module "test" {
  source            = "../../"
  luther_env        = "env"
  luther_project    = "project"
  app_naked_domain  = "example.com"
  app_target_domain = "target.example.com"
  origin_url        = "origin.example.com"
  use_302           = true

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
    random        = random
  }
}
