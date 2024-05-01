locals {
  component = var.component_replica == "" ? format("%s-replica", var.component) : var.component_replica
}


data "aws_region" "primary" {}
data "aws_region" "replica" {
  provider = aws.replica
}

module "aws_s3_bucket_replica" {
  source = "../aws-s3-bucket"

  luther_project    = var.luther_project
  luther_env        = var.luther_env
  component         = local.component
  random_identifier = var.random_identifier_replica
  aws_kms_key_arn   = var.aws_kms_key_arn_replica
  lifecycle_rules   = var.lifecycle_rules_replica
  force_destroy     = var.force_destroy

  providers = {
    aws = aws.replica
  }
}

module "aws_s3_bucket" {
  source = "../aws-s3-bucket"

  luther_project    = var.luther_project
  luther_env        = var.luther_env
  component         = var.component
  random_identifier = var.random_identifier
  aws_kms_key_arn   = var.aws_kms_key_arn
  lifecycle_rules   = var.lifecycle_rules
  force_destroy     = var.force_destroy

  dr_bucket_replication       = true
  replication_role_arn        = module.replication_role.role_arn
  replication_destination_arn = module.aws_s3_bucket_replica.arn
  destination_kms_key_arn     = var.aws_kms_key_arn_replica
  replicate_deletes           = var.replicate_deletes

  providers = {
    aws = aws
  }
}

module "replication_role" {
  source = "../aws-s3-replication-role"

  luther_project = var.luther_project
  aws_region     = data.aws_region.primary.name
  aws_region_dr  = data.aws_region.replica.name
  luther_env     = var.luther_env
  component      = local.component
  bucket_source_arns = [
    module.aws_s3_bucket.arn,
  ]
  bucket_destination_arns = [
    module.aws_s3_bucket_replica.arn,
  ]
  source_kms_key_ids      = [var.aws_kms_key_arn]
  destination_kms_key_ids = [var.aws_kms_key_arn_replica]
}
