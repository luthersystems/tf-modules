data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-west-2"
}

resource "aws_kms_key" "test" {}

module "test" {
  aws_account_id         = data.aws_caller_identity.current.account_id
  source                 = "../../"
  luther_env             = "env"
  luther_project         = "project"
  volumes_aws_kms_key_id = aws_kms_key.test.arn
  aws_kms_key_arns       = [aws_kms_key.test.arn]

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }
}
