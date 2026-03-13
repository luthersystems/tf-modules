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

locals {
  tfstate_kms_key_arn = try(aws_kms_key.tfstate[0].arn, "")
  tfstate_kms_alias   = try(aws_kms_alias.tfstate[0].arn, "")
  tfstate_bucket_name = try(module.aws_s3_bucket_tfstate[0].bucket, "")
}

resource "aws_kms_key" "tfstate" {
  count = var.create_state_bucket ? 1 : 0

  description = "tfstate encryption key for ${var.project} ${var.env} environment"
  tags        = module.luthername_kms_key.0.tags
}

resource "aws_kms_alias" "tfstate" {
  count = var.create_state_bucket ? 1 : 0

  name          = format("alias/%s", var.kms_alias_suffix)
  target_key_id = local.tfstate_kms_key_arn
}

output "aws_kms_key_id" {
  value = var.create_state_bucket ? local.tfstate_kms_alias : ""

  precondition {
    condition     = !var.create_state_bucket || local.tfstate_kms_alias != ""
    error_message = "State bucket bootstrap is incomplete: expected the tfstate KMS key/alias to exist when create_state_bucket=true."
  }
}

module "aws_s3_bucket_tfstate" {
  source = "../aws-s3-bucket"

  count = var.create_state_bucket ? 1 : 0

  luther_project  = var.project
  luther_env      = var.env
  component       = "tfstate"
  aws_kms_key_arn = local.tfstate_kms_key_arn

  force_destroy = true

  providers = {
    aws    = aws
    random = random
  }
}

output "aws_s3_bucket_tfstate" {
  value = var.create_state_bucket ? local.tfstate_bucket_name : ""

  precondition {
    condition     = !var.create_state_bucket || local.tfstate_bucket_name != ""
    error_message = "State bucket bootstrap is incomplete: expected the tfstate S3 bucket to exist when create_state_bucket=true."
  }
}
