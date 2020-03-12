variable "aws_region" {
  default = "eu-west-2"
}

variable "aws_region_short_code" {
  default = {
    eu-west-1    = "ie"
    eu-west-2    = "ln"
    us-west-1    = "va"
    us-west-2    = "or"
    eu-central-1 = "de"
  }
}

provider "aws" {
}

provider "template" {
  version = "~> 0.1"
}

provider "null" {
  version = "~> 0.1"
}
