resource "random_string" "aws_s3_bucket_sftp" {
  length  = 4
  upper   = false
  special = false
}

module "aws_s3_bucket_sftp" {
  source = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//aws-s3-bucket?ref=v3.1.0"

  luther_project        = "${var.luther_project}"
  aws_region            = "${var.aws_region}"
  aws_region_short_code = "${var.aws_region_short_code}"
  aws_kms_key_arn       = "${var.bucket_kms_key_arn}"
  luther_env            = "${var.luther_env}"
  component             = "sftp"
  random_identifier     = "${random_string.aws_s3_bucket_sftp.result}"

  providers = {
    aws      = "aws"
    template = "template"
  }
}

output "bucket" {
  value = "${module.aws_s3_bucket_sftp.bucket}"
}

output "bucket_arn" {
  value = "${module.aws_s3_bucket_sftp.arn}"
}
