data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  alias = "us-east-1"
}

module "test" {
  aws_account_id = data.aws_caller_identity.current.account_id
  source         = "../../"
  luther_env     = "env"
  luther_project = "project"

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }
}
