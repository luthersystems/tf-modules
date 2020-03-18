module "luthername_s3_bucket_logs" {
  source                = "../luthername"
  luther_project        = var.luther_project
  aws_region            = var.aws_region
  aws_region_short_code = var.aws_region_short_code
  luther_env            = var.luther_env
  component             = var.component
  resource              = "s3"
  id                    = var.random_identifier
}

locals {
  aws_account_number = var.aws_alb_access_log_accounts[var.aws_region]
  aws_logging_arn    = "arn:aws:iam::${local.aws_account_number}:root"

  bucket_name = "luther-${module.luthername_s3_bucket_logs.names[0]}"
  bucket_arn  = "arn:aws:s3:::${local.bucket_name}"
  # This is a bit permissive, but several environments will have their
  # access logs written under this root key prefix.
  bucket_resource = "${local.bucket_arn}/access_logs/*"
}

resource "aws_s3_bucket" "logs" {
  bucket = local.bucket_name
  acl    = "private"
  region = var.aws_region

  versioning {
    enabled = true
    #mfa_delete = true
  }

  policy = data.aws_iam_policy_document.logs_alb.json

  lifecycle_rule {
    prefix  = "access_logs/"
    enabled = true

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      days = 60
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.aws_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = {
    Name        = local.bucket_name
    Project     = module.luthername_s3_bucket_logs.luther_project
    Environment = module.luthername_s3_bucket_logs.luther_env
    Component   = module.luthername_s3_bucket_logs.component
    Resource    = module.luthername_s3_bucket_logs.resource
    ID          = module.luthername_s3_bucket_logs.ids[0]
  }
}

# Allow the AWS account which operates ALBs to write access logs
# aws_s3_bucket.logs.
data "aws_iam_policy_document" "logs_alb" {
  statement {
    actions   = ["s3:PutObject"]
    resources = [local.bucket_resource]

    principals {
      type        = "AWS"
      identifiers = [local.aws_logging_arn]
    }
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = [local.bucket_resource]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    actions   = ["s3:GetBucketAcl"]
    resources = [local.bucket_arn]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}
