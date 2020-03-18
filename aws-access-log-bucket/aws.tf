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

variable "aws_alb_access_log_accounts" {
  default = {
    "us-east-1"      = "127311923021"
    "us-east-2"      = "033677994240"
    "us-west-1"      = "027434742980"
    "us-west-2"      = "797873946194"
    "ca-central-1"   = "985666609251"
    "eu-west-1"      = "156460612806"
    "eu-central-1"   = "054676820928"
    "eu-west-2"      = "652711504416"
    "ap-northeast-1" = "582318560864"
    "ap-northeast-2" = "600734575887"
    "ap-southeast-1" = "114774131450"
    "ap-southeast-2" = "783225319266"
    "ap-south-1"     = "718504428378"
    "sa-east-1"      = "507241528517"
  }
}
