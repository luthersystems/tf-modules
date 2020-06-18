module "aws_s3_bucket_static" {
  source         = "../../"
  luther_project = "project"
  aws_region     = "eu-west-2"
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

provider "aws" {
  region = "eu-west-2"
}

provider "random" {}
