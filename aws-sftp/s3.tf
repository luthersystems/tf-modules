resource "random_string" "aws_s3_bucket_sftp" {
  length  = 4
  upper   = false
  special = false
}

module "aws_s3_bucket_sftp" {
  source = "../aws-s3-bucket"

  luther_project        = var.luther_project
  aws_region            = var.aws_region
  aws_region_short_code = var.aws_region_short_code
  aws_kms_key_arn       = var.bucket_kms_key_arn
  luther_env            = var.luther_env
  component             = "sftp"
  random_identifier     = random_string.aws_s3_bucket_sftp.result

  providers = {
    aws    = aws
    random = random
  }
}

output "bucket" {
  value = module.aws_s3_bucket_sftp.bucket
}

output "bucket_arn" {
  value = module.aws_s3_bucket_sftp.arn
}
