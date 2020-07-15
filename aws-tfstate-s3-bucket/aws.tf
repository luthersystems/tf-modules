# This file declares the basic AWS configuration for the project

variable "aws_region" {
  type = string
}

variable "aws_region_short_code" {
  default = {
    eu-west-1    = "ie"
    eu-central-1 = "de"
    eu-west-2    = "ln"
    us-west-1    = "va"
    us-west-2    = "or"
  }
}
