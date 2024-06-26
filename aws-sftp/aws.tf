# This file declares the basic AWS configuration for the project

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_region_short_code" {
  default = {
    eu-central-1 = "de"
    eu-west-1    = "ie"
    eu-west-2    = "ln"
    us-west-1    = "va"
    us-west-2    = "or"
  }
}

# NOTE: we need to make this explicit to avoid breakage when this changes
# within a region.
variable "aws_availability_zones" {
  default = {
    "eu-central-1" = [
      "eu-central-1a",
      "eu-central-1b",
      "eu-central-1c",
    ]
    "eu-west-2" = [
      "eu-west-2a",
      "eu-west-2b",
      "eu-west-2c",
    ]
  }
}

locals {
  region_availability_zones = var.aws_availability_zones[var.aws_region]
}
