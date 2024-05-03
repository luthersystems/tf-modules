terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {}

module "test" {
  source            = "../../"
  luther_env        = "env"
  luther_project    = "project"
  app_naked_domain  = "example.com"
  app_target_domain = "target.example.com"
  origin_url        = "origin.example.com"

  providers = {
    aws = aws
  }
}
