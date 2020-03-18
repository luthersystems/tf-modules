variable "aws_region" {
  default = "eu-west-2"
}

variable "aws_ssh_key_name" {
  type = string
}

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
