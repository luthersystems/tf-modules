locals {
  s3_common_resource_arns = compact([
    var.common_static_s3_bucket_arn != "" ? "${var.common_static_s3_bucket_arn}/*" : "",
    var.common_external_s3_bucket_arn != "" ? "${var.common_external_s3_bucket_arn}/*" : ""
  ])
}

data "aws_iam_policy_document" "fabric_peer_orderer" {

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

module "fabric_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "fabric"

  oidc_provider_name         = local.oidc_provider_name
  oidc_provider_arn          = local.oidc_provider_arn
  service_account            = "fabric"
  namespace_service_accounts = var.fabric_namespace_service_accounts
  add_policy                 = true
  policy                     = data.aws_iam_policy_document.fabric_peer_orderer.json
  id                         = random_string.fabric.result

  providers = {
    aws = aws
  }
}

locals {
  fabric_peer_service_account_role_arn    = module.fabric_service_account_iam_role.arn
  fabric_cli_service_account_role_arn     = module.fabric_service_account_iam_role.arn
  fabric_orderer_service_account_role_arn = module.fabric_service_account_iam_role.arn
}

output "fabric_peer_service_account_iam_role_arn" {
  value = local.fabric_peer_service_account_role_arn
}

output "fabric_cli_service_account_iam_role_arn" {
  value = local.fabric_cli_service_account_role_arn
}

output "fabric_orderer_service_account_iam_role_arn" {
  value = local.fabric_orderer_service_account_role_arn
}
