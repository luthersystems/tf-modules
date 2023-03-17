locals {
  default_role_arn   = "arn:aws:iam::967058059066:role/dlm-lifecycle"
  execution_role_arn = var.role_arn == "" ? local.default_role_arn : var.role_arn
  execution_role     = split("/", local.execution_role_arn)[1]

  source_ebs_kms_arns = data.aws_ebs_volume.target_volume.*.kms_key_id
}


data "aws_iam_policy_document" "kms_ebs_dr_snapshots" {
  for_each = { for s in var.cross_region_settings : s.region => s.cmk_arn if s.cmk_arn != null }

  statement {
    actions = [
      "kms:RevokeGrant",
      "kms:CreateGrant",
      "kms:ListGrants",

    ]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [true]
    }

    resources = compact(concat(each.value, local.source_ebs_kms_arns))
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = compact(concat(each.value, local.source_ebs_kms_arns))
  }
}

resource "aws_iam_policy" "kms_ebs_dr_snapshots" {
  for_each = data.aws_iam_policy_document.kms_ebs_dr_snapshots

  name        = "DestinationKmsEBSSnapshotsPolicy"
  description = "KMS permissions for the destination key in cross-region EBS snapshot replication"

  policy = each.value.json
}

resource "aws_iam_role_policy_attachment" "kms_ebs_dr_snapshots_attach" {
  for_each = aws_iam_policy.kms_ebs_dr_snapshots

  policy_arn = each.value.arn
  role       = local.execution_role
}

data "aws_ebs_volumes" "target_volumes" {
  tags = var.target_tags
}

data "aws_ebs_volume" "target_volume" {
  for_each = data.aws_ebs_volumes.target_volumes.ids

  most_recent = true

  filter {
    name   = "volume-id"
    values = each.value
  }
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
