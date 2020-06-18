module "luthername_s3_replication" {
  source = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=v23.2.0"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = var.component
  resource       = "s3"
  subcomponent   = "replication"
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
  name   = "iam-role-policy-replication"
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
    ]

    resources = formatlist("%s/*", var.bucket_source_arns)
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
    ]

    resources = formatlist("%s/*", var.bucket_destination_arns)
  }

  statement {
    actions = [
      "kms:Decrypt",
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
      "kms:GenerateDataKey",
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