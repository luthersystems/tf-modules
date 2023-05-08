module "luthername_kms_key_main" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "storage"
  resource       = "kms"
  id             = random_string.kms_key_main.result
}

resource "random_string" "kms_key_main" {
  length  = 4
  upper   = false
  special = false
}

resource "aws_kms_key" "main" {
  description = "Master KMS key for storage encryption"
  policy      = data.aws_iam_policy_document.kms_key_main.json
  tags        = module.luthername_kms_key_main.tags
}

data "aws_iam_role" "autoscaling_service_role" {
  name = "AWSServiceRoleForAutoScaling"
}

data "aws_iam_policy_document" "kms_key_main" {
  # Default statement attached to any kms key
  statement {
    sid = "Enable IAM User Permissions"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.external_access_principials) == 0 ? [] : [1]

    content {
      sid = "External account S3 Decrypt access"

      principals {
        type        = "AWS"
        identifiers = var.external_access_principials
      }

      actions = [
        "kms:Decrypt",
      ]
      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"

        values = [
          "s3.${local.region}.amazonaws.com",
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.external_access_principials) == 0 ? [] : [1]

    content {
      sid = "External account key info access"

      principals {
        type        = "AWS"
        identifiers = var.external_access_principials
      }

      actions = [
        "kms:DescribeKey",
      ]
      resources = ["*"]
    }
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.autoscaling_service_role.arn]
    }
  }

  statement {
    sid = "Allow attachment of persistent resources"
    actions = [
      "kms:CreateGrant",
    ]
    effect    = "Allow"
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.autoscaling_service_role.arn]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${module.luthername_kms_key_main.name}"
  target_key_id = aws_kms_key.main.key_id
}

output "kms_key_main_arn" {
  value = aws_kms_key.main.arn
}

output "kms_alias_main_arn" {
  value = aws_kms_alias.main.arn
}
