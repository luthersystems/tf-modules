data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  alias = "us-east-1"
}

module "test" {
  source         = "../../"
  luther_env     = "env"
  luther_project = "project"

  kubernetes_version  = "1.23"
  storage_kms_key_arn = ""

  # Exercise the opt-in pass-through to eks-vpc (tf-modules#84).
  eks_secrets_encryption     = true
  eks_secrets_kms_key_arn    = "arn:aws:kms:us-west-2:123456789012:key/00000000-0000-0000-0000-000000000000"
  eks_worker_imdsv2_required = true

  monitoring = false

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
    null          = null
    local         = local
    random        = random
    external      = external
    tls           = tls
  }
}
