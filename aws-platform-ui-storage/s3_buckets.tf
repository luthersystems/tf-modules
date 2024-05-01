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
  count  = length(var.external_access_principials) == 0 ? 0 : 1
  bucket = module.static_bucket.bucket
  policy = data.aws_iam_policy_document.external_access.json
}

data "aws_iam_policy_document" "external_access" {
  dynamic "statement" {
    for_each = length(var.external_access_principials) == 0 ? [] : [1]

    content {
      sid = "externalGet"

      principals {
        type        = "AWS"
        identifiers = var.external_access_principials
      }

      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::${module.static_bucket.bucket}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.external_access_principials) == 0 ? [] : [1]

    content {
      sid = "externalList"

      principals {
        type        = "AWS"
        identifiers = var.external_access_principials
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
