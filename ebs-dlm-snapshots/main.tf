locals {
  default_role_arn   = "arn:aws:iam::967058059066:role/dlm-lifecycle"
  execution_role_arn = "${var.role_arn == "" ? local.default_role_arn : var.role_arn}"
}

resource "aws_dlm_lifecycle_policy" "policy" {
  description        = "${var.description}"
  execution_role_arn = "${local.execution_role_arn}"
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "snapshot schedule"

      create_rule {
        interval      = "${var.interval_hours}"
        interval_unit = "HOURS"
        times         = ["${var.times}"]
      }

      retain_rule {
        count = "${var.retain_count}"
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true
    }

    target_tags = "${var.target_tags}"
  }
}
