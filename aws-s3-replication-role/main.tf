resource "random_string" "id" {
  count   = var.random_identifier == "" ? 1 : 0
  length  = 4
  upper   = false
  special = false
}

locals {
  random_id = var.random_identifier == "" ? random_string.id.0.result : var.random_identifier
}

module "luthername_s3_replication" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = var.component
  resource       = "s3"
  subcomponent   = "replication"
  id             = local.random_id
}

resource "aws_iam_role" "replication" {
  name               = module.luthername_s3_replication.name
  assume_role_policy = data.aws_iam_policy_document.s3_replication_assume_role.json
  tags               = module.luthername_s3_replication.tags
}

data "aws_iam_policy_document" "s3_replication_assume_role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "replication" {
  name   = format("iam-role-policy-replication-%s", local.random_id)
  role   = aws_iam_role.replication.name
  policy = data.aws_iam_policy_document.replication.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = var.bucket_source_arns
  }

  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = formatlist("%s/*", var.bucket_source_arns)
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = formatlist("%s/*", var.bucket_destination_arns)
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
    ]
    resources = var.source_kms_key_ids

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
    ]
    resources = var.destination_kms_key_ids

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_region_dr}.amazonaws.com"]
    }
  }
}

output "role_arn" {
  value = aws_iam_role.replication.arn
}
