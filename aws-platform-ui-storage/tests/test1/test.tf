data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  alias = "dr"
}

module "test" {
  source         = "../../"
  luther_env     = "env"
  luther_project = "project"

  ci_github_repos = []

  # Exercise the EKS secrets key (tf-modules#84).
  eks_secrets_kms_key = true

  providers = {
    aws    = aws
    aws.dr = aws.dr
    random = random
  }
}
