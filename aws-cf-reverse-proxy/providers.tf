provider "aws" {
  region  = var.aws_region
  version = "~> 2.53"
}

provider "aws" {
  alias   = "eu-central-1"
  region  = "eu-central-1"
  version = "~> 2.53"
}

provider "aws" {
  alias   = "us-east-1"
  region  = "us-east-1"
  version = "~> 2.53"
}
