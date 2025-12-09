module "role_name" {
  source = "../luthername"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "role"
  subcomponent   = var.service_account
  id             = var.id
}

resource "aws_iam_role" "role" {
  name               = module.role_name.names[0]
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

output "name" {
  value = aws_iam_role.role.name
}

output "arn" {
  value = aws_iam_role.role.arn
}

locals {
  namespace_service_accounts = length(var.namespace_service_accounts) == 0 ? {
    "${var.k8s_namespace}" = [var.service_account]
  } : var.namespace_service_accounts

  all_service_accounts = flatten([
    for ns, accounts in local.namespace_service_accounts : [
      for account in accounts : "system:serviceaccount:${ns}:${account}"
    ]
  ])
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_name}:sub"
      values   = local.all_service_accounts
    }
  }

  dynamic "statement" {
    for_each = length(var.trusted_role_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.trusted_role_arns
      }
      actions = ["sts:AssumeRole"]
    }
  }
}

resource "aws_iam_role_policy" "main" {
  count  = var.add_policy ? 1 : 0
  role   = aws_iam_role.role.name
  name   = var.policy_name
  policy = var.policy
}
