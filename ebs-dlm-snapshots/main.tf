locals {
  default_role_arn   = "arn:aws:iam::967058059066:role/dlm-lifecycle"
  execution_role_arn = var.role_arn == "" ? local.default_role_arn : var.role_arn
}

resource "aws_dlm_lifecycle_policy" "policy" {
  description        = var.description
  execution_role_arn = local.execution_role_arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "snapshot schedule"

      create_rule {
        interval      = var.interval_hours
        interval_unit = "HOURS"
        times         = var.times
      }

      retain_rule {
        count = var.retain_count
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      dynamic "cross_region_copy_rule" {
        for_each = var.cross_region_settings
        content {
          target    = cross_region_copy_rule.value.region
          cmk_arn   = cross_region_copy_rule.value.cmk_arn
          copy_tags = true
          encrypted = true
          retain_rule {
            interval      = cross_region_copy_rule.value.interval
            interval_unit = cross_region_copy_rule.value.interval_unit
          }
        }
      }

      copy_tags = true
    }

    target_tags = var.target_tags
  }
}
