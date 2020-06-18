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
  acl    = "private"
  region = var.aws_region

  versioning {
    enabled = true
    #mfa_delete = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.aws_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  dynamic "replication_configuration" {
    for_each = var.dr_bucket_replication ? [1] : []

    content {
      role = var.replication_role_arn

      rules {
        id     = "disaster-recovery"
        status = "Enabled"

        destination {
          bucket             = var.replication_destination_arn
          replica_kms_key_id = var.destination_kms_key_arn
          storage_class      = "STANDARD"
        }

        source_selection_criteria {
          sse_kms_encrypted_objects {
            enabled = true
          }
        }
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules

    content {
      id      = lifecycle_rule.value.id
      enabled = lifecycle_rule.value.enabled

      expiration {
        days = lifecycle_rule.value.expiration_days
      }
    }
  }

  tags = merge(
    module.luthername_s3_bucket.tags,
    { Name = "luther-${module.luthername_s3_bucket.name}" }
  )
}
