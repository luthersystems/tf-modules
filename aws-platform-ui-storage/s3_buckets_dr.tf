
module "replication_role" {
  source         = "../aws-s3-replication-role"
  luther_project = var.luther_project
  aws_region     = local.region
  aws_region_dr  = local.region_dr
  luther_env     = var.luther_env
  component      = "app"
  bucket_source_arns = [
    module.static_bucket.arn,
  ]
  bucket_destination_arns = [
    local.static_bucket_dr_arn,
  ]
  source_kms_key_ids      = [aws_kms_key.main.arn]
  destination_kms_key_ids = [local.kms_key_dr_arn]

  providers = {
    aws = aws
  }
}

module "static_bucket_dr" {
  source          = "../aws-s3-bucket"
  luther_project  = var.luther_project
  luther_env      = var.luther_env
  component       = "static"
  aws_kms_key_arn = local.kms_key_dr_arn

  providers = {
    aws    = aws.dr
    random = random
  }
}

locals {
  static_bucket_replication = local.region_dr != ""
  replication_role_arn      = module.replication_role.role_arn
  static_bucket_dr_arn      = module.static_bucket_dr.arn
  static_bucket_dr          = module.static_bucket_dr.bucket
}

output "static_bucket_dr" {
  value = local.static_bucket_dr
}

output "static_bucket_dr_arn" {
  value = local.static_bucket_dr_arn
}
