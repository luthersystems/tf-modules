terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 3.0"
      configuration_aliases = [aws.us-east-1]
    }

    random = {
      source = "hashicorp/random"
    }
  }
}
