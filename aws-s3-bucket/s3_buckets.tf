resource "random_string" "id" {
  count   = var.random_identifier == "" ? 1 : 0
  length  = 4
  upper   = false
  special = false
}

locals {
  random_id = var.random_identifier == "" ? random_string.id.0.result : var.random_identifier
}

module "luthername_s3_bucket" {
  source                = "../luthername"
  luther_project        = var.luther_project
  aws_region            = var.aws_region
  aws_region_short_code = var.aws_region_short_code
  luther_env            = var.luther_env
  component             = var.component
  resource              = "s3"
  id                    = local.random_id
}

resource "aws_s3_bucket" "bucket" {
  bucket = "luther-${module.luthername_s3_bucket.names[0]}"

  tags = merge(
    module.luthername_s3_bucket.tags,
    { Name = "luther-${module.luthername_s3_bucket.name}" }
  )

  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_acl" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.aws_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "bucket" {
  count      = var.dr_bucket_replication ? 1 : 0
  bucket     = aws_s3_bucket.bucket.id
  depends_on = [aws_s3_bucket_versioning.bucket]
  role       = var.replication_role_arn

  rule {
    filter {}

    id     = "disaster-recovery"
    status = "Enabled"

    delete_marker_replication {
      status = var.replicate_deletes ? "Enabled" : "Disabled"
    }

    destination {
      bucket        = var.replication_destination_arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = var.destination_kms_key_arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      expiration {
        days = rule.value.expiration_days
      }
    }
  }
}
