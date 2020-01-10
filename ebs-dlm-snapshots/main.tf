data "aws_iam_role" "dlm" {
  name = "${var.role_name}"
}

resource "aws_dlm_lifecycle_policy" "policy" {
  description        = "${var.description}"
  execution_role_arn = "${data.aws_iam_role.dlm.arn}"
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
