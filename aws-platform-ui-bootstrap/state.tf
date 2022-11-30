module "luthername_kms_key" {
  source = "../luthername"

  count = var.create_state_bucket ? 1 : 0

  luther_project = var.project
  aws_region     = local.region
  luther_env     = var.env
  org_name       = var.org_name
  component      = "tfstate"
  resource       = "kms"
}

resource "aws_kms_key" "tfstate" {
  count = var.create_state_bucket ? 1 : 0

  description = "tfstate encryption key for ${var.project} ${var.env} environment"
  tags        = module.luthername_kms_key.0.tags
}

resource "aws_kms_alias" "tfstate" {
  count = var.create_state_bucket ? 1 : 0

  name          = format("alias/%s", var.kms_alias_suffix)
  target_key_id = aws_kms_key.tfstate.0.arn
}

output "aws_kms_key_id" {
  value = var.create_state_bucket ? aws_kms_alias.tfstate.0.arn : ""
}

module "aws_s3_bucket_tfstate" {
  source = "../aws-s3-bucket"

  count = var.create_state_bucket ? 1 : 0

  luther_project  = var.project
  luther_env      = var.env
  aws_region      = local.region
  component       = "tfstate"
  aws_kms_key_arn = aws_kms_key.tfstate.0.arn

  providers = {
    aws    = aws
    random = random
  }
}

output "aws_s3_bucket_tfstate" {
  value = var.create_state_bucket ? module.aws_s3_bucket_tfstate.0.bucket : ""
}
