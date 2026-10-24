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

  tags = {
    Name        = local.bucket_name
    Project     = module.luthername_s3_bucket_logs.luther_project
    Environment = module.luthername_s3_bucket_logs.luther_env
    Component   = module.luthername_s3_bucket_logs.component
    Resource    = module.luthername_s3_bucket_logs.resource
    ID          = module.luthername_s3_bucket_logs.ids[0]
  }
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"

  # S3 refuses concurrent changes to one bucket's access settings (409
  # OperationAborted), so apply these after the public access block.
  depends_on = [aws_s3_bucket_public_access_block.logs]
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_alb.json

  depends_on = [aws_s3_bucket_public_access_block.logs]
}

# Block every form of public access. The bucket is private by design: log
# delivery writes through the bucket policy, which names the ALB log account
# and the delivery.logs.amazonaws.com service, so no public grant is needed. Without this block, one stray
# ACL or bucket policy could make it public. Adding it creates a new
# resource and changes nothing on the bucket.
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "logs" {
  count      = var.dr_bucket_replication ? 1 : 0
  bucket     = aws_s3_bucket.logs.id
  depends_on = [aws_s3_bucket_versioning.logs]
  role       = var.replication_role_arn

  rule {
    id     = "disaster-recovery"
    status = "Enabled"

    destination {
      bucket        = var.replication_destination_arn
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = var.lifecycle_expiration_id
    status = "Enabled"

    filter {
      prefix = "access_logs/"
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 60
    }
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
