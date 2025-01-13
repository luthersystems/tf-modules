terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.dr_region]
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
  required_version = ">= 1.0"
}
