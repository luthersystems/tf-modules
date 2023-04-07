terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 2.0"
      configuration_aliases = [aws.replica]
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
