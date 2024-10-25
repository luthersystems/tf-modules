module "static_bucket" {
  source          = "../aws-s3-bucket"
  luther_project  = var.luther_project
  luther_env      = var.luther_env
  component       = "static"
  aws_kms_key_arn = aws_kms_key.main.arn

  providers = {
    aws    = aws
    random = random
  }
}

resource "aws_s3_bucket_policy" "static" {
  count  = length(var.external_access_principals) == 0 ? 0 : 1
  bucket = module.static_bucket.bucket
  policy = data.aws_iam_policy_document.external_access.json
}

locals {
  s3_access_principals = compact(
    concat(var.external_access_principals, var.ci_static_access ? [aws_iam_role.ci_role.arn] : [])
  )
}

data "aws_iam_policy_document" "external_access" {
  dynamic "statement" {
    for_each = length(local.s3_access_principals) == 0 ? [] : [1]

    content {
      sid = "externalGet"

      principals {
        type        = "AWS"
        identifiers = local.s3_access_principals
      }

      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::${module.static_bucket.bucket}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(local.s3_access_principals) == 0 ? [] : [1]

    content {
      sid = "externalList"

      principals {
        type        = "AWS"
        identifiers = local.s3_access_principals
      }

      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::${module.static_bucket.bucket}"]
    }
  }

}

output "static_bucket" {
  value = module.static_bucket.bucket
}

output "static_bucket_arn" {
  value = module.static_bucket.arn
}
