resource "aws_iam_role" "dlm" {
  name               = "dlm-lifecycle-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = "${aws_iam_role.dlm.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "policy" {
  description        = "Fabric DLM lifecycle policy"
  execution_role_arn = "${aws_iam_role.dlm.arn}"
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Fabric volume snapshots"

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
