locals {
  s3_common_resource_arns = compact([
    var.common_static_s3_bucket_arn != "" ? "${var.common_static_s3_bucket_arn}/*" : "",
    var.common_external_s3_bucket_arn != "" ? "${var.common_external_s3_bucket_arn}/*" : ""
  ])
}

data "aws_iam_policy_document" "fabric_ro" {

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "s3.${var.aws_region}.amazonaws.com",
      ]
    }

    resources = var.aws_kms_key_arns
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = concat(local.s3_common_resource_arns, local.s3_prefixes)
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = compact([
      var.storage_s3_bucket_arn,
      var.common_static_s3_bucket_arn,
      var.common_external_s3_bucket_arn,
    ])
  }
}

data "aws_iam_policy_document" "fabric_snapshot" {

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "s3.${var.aws_region}.amazonaws.com",
      ]
    }

    resources = var.aws_kms_key_arns
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = concat(local.s3_common_resource_arns, local.s3_prefixes)
  }

  dynamic "statement" {
    for_each = length(var.storage_s3_bucket_snapshot_prefix) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:GetObject",
      ]
      resources = [
        "${var.storage_s3_bucket_arn}/${var.luther_env}/${var.storage_s3_bucket_snapshot_prefix}/*",
      ]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = compact([
      var.storage_s3_bucket_arn,
      var.common_static_s3_bucket_arn,
      var.common_external_s3_bucket_arn,
    ])
  }
}

resource "random_string" "fabric" {
  length  = 4
  upper   = false
  special = false
}

module "fabric_ro_service_account_iam_role" {

  for_each = toset(var.fabric_namespace_ro_service_accounts)

  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "fabric"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "fabric-ro"
  k8s_namespace      = each.key
  add_policy         = true
  policy             = data.aws_iam_policy_document.fabric_ro.json
  id                 = random_string.fabric.result

  providers = {
    aws = aws
  }
}

module "fabric_snapshot_service_account_iam_role" {

  for_each = toset(var.fabric_namespace_snapshot_service_accounts)

  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "fabric"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "fabric-snapshot"
  k8s_namespace      = each.key
  add_policy         = true
  policy             = data.aws_iam_policy_document.fabric_snapshot.json
  id                 = random_string.fabric.result

  providers = {
    aws = aws
  }
}


locals {
  fabric_ro_service_account_role_arns       = module.fabric_ro_service_account_iam_role.*.arn
  fabric_snapshot_service_account_role_arns = module.fabric_snapshot_service_account_iam_role.*.arn
}

output "fabric_ro_service_account_iam_role_arns" {
  value = local.fabric_ro_service_account_role_arns
}

output "fabric_snapshot_service_account_iam_role_arns" {
  value = local.fabric_snapshot_service_account_role_arns
}
