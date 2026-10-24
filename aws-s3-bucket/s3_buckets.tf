resource "random_string" "id" {
  count   = var.random_identifier == "" ? 1 : 0
  length  = 4
  upper   = false
  special = false
}

locals {
  random_id = var.random_identifier == "" ? random_string.id[0].result : var.random_identifier
}

data "aws_region" "current" {}

module "luthername_s3_bucket" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = data.aws_region.current.name
  luther_env     = var.luther_env
  component      = var.component
  resource       = "s3"
  id             = local.random_id
}

resource "aws_s3_bucket" "bucket" {
  bucket = "luther-${module.luthername_s3_bucket.names[0]}"

  tags = merge(
    module.luthername_s3_bucket.tags,
    { Name = "luther-${module.luthername_s3_bucket.name}" }
  )

  force_destroy = var.force_destroy

  lifecycle {
    ignore_changes = [server_side_encryption_configuration, versioning]
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block every form of public access. The bucket is private by design;
# callers grant access to named principals with their own bucket policy.
# Without this block, one stray ACL or bucket policy could make it public. Adding it creates a new resource and changes nothing on the bucket.
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    bucket_key_enabled = false

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

output "versioning_id" {
  value = aws_s3_bucket_versioning.bucket.id
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
