# This file declares the basic AWS configuration for the project

variable "aws_region" {
  default = "eu-west-2"
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

data "template_file" "availability_zones" {
  count    = "${var.replication}"
  template = "$${az}"

  vars {
    az = "${element(var.aws_availability_zones, count.index)}"
  }
}

# This map contains the all instance types that can have the ebs_optimized
# configuration enabled.  To determine the the value of the configuration
# use the "lookup" interoplation function with a default of `false`.
#
# For details about the instances in the map see the AWS documentation
# regarding EBS-optimized instances.
#
# http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSOptimized.html
variable "aws_ebs_optimizable_instance_types" {
  default = {
    "c1.xlarge"   = true
    "c3.xlarge"   = true
    "c3.2xlarge"  = true
    "c3.4xlarge"  = true
    "c4.large"    = true
    "c4.xlarge"   = true
    "c4.2xlarge"  = true
    "c4.4xlarge"  = true
    "c4.8xlarge"  = true
    "d2.xlarge"   = true
    "d2.2xlarge"  = true
    "d2.4xlarge"  = true
    "d2.8xlarge"  = true
    "g2.2xlarge"  = true
    "i2.xlarge"   = true
    "i2.2xlarge"  = true
    "i2.4xlarge"  = true
    "m1.large"    = true
    "m1.xlarge"   = true
    "m2.2xlarge"  = true
    "m2.4xlarge"  = true
    "m3.xlarge"   = true
    "m3.2xlarge"  = true
    "m4.large"    = true
    "m4.xlarge"   = true
    "m4.2xlarge"  = true
    "m4.4xlarge"  = true
    "m4.10xlarge" = true
    "m4.16xlarge" = true
    "p2.xlarge"   = true
    "p2.8xlarge"  = true
    "p2.16xlarge" = true
    "r3.xlarge"   = true
    "r3.2xlarge"  = true
    "r3.4xlarge"  = true
    "r4.large"    = true
    "r4.xlarge"   = true
    "r4.2xlarge"  = true
    "r4.4xlarge"  = true
    "r4.8xlarge"  = true
    "r4.16xlarge" = true
    "x1.16xlarge" = true
    "x1.32xlarge" = true
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

    # us-gov-wets-1 and cn-north-1 require separate aws accounts
    "us-gov-west-1" = "048591011584"
    "cn-north-1"    = "638102146993"
  }
}
