module "luthername_env_admin_role" {
  source         = "github.com/luthersystems/tf-modules//luthername?ref=v52.0.2"
  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  component      = "iam"
  resource       = "env-admin"
}

locals {
  env_admin_access_principals = concat(var.external_access_principals, [aws_iam_role.ci_role.arn])
}

data "aws_iam_policy_document" "env_admin_assume_role" {
  dynamic "statement" {
    for_each = length(local.env_admin_access_principals) == 0 ? [] : [1]
    content {
      sid = "allowEnvAdminAssumeRoleAccess"

      principals {
        type        = "AWS"
        identifiers = local.env_admin_access_principals
      }

      actions = ["sts:AssumeRole"]
    }
  }
}

resource "aws_iam_role" "env_admin_role" {
  name               = "${module.luthername_env_admin_role.name}-role"
  description        = "Provides environment Admin level access"
  assume_role_policy = data.aws_iam_policy_document.env_admin_assume_role.json

  tags = module.luthername_env_admin_role.tags
}

output "env_admin_role_name" {
  value = aws_iam_role.env_admin_role.name
}

output "env_admin_role_arn" {
  value = aws_iam_role.env_admin_role.arn
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

locals {
  ci_github_sub_str = "repo:${var.ci_github_org}/${var.ci_github_repo}:environment:${var.ci_github_env}"
}

data "aws_iam_policy_document" "ci_assume_role" {

  dynamic "statement" {
    for_each = length(var.external_access_principals) == 0 ? [] : [1]
    content {
      sid = "allowAdminAssumeCIRoleAccess"

      principals {
        type        = "AWS"
        identifiers = var.external_access_principals
      }

      actions = ["sts:AssumeRole"]
    }
  }

  dynamic "statement" {
    for_each = var.has_github ? [1] : []
    content {
      sid    = "allowGitHubOIDCAssumeRole"
      effect = "Allow"

      principals {
        type        = "Federated"
        identifiers = [aws_iam_openid_connect_provider.github.arn]
      }

      actions = ["sts:AssumeRoleWithWebIdentity"]

      condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:aud"
        values   = ["sts.amazonaws.com"]
      }

      condition {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:sub"
        values   = [local.ci_github_sub_str]
      }
    }
  }
}

module "luthername_ci_role" {
  source         = "github.com/luthersystems/tf-modules//luthername?ref=v52.0.2"
  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  component      = "iam"
  resource       = "ci"
}

resource "aws_iam_role" "ci_role" {
  name               = "${module.luthername_ci_role.name}-role"
  description        = "Provides CI level access"
  assume_role_policy = data.aws_iam_policy_document.ci_assume_role.json

  tags = module.luthername_ci_role.tags
}

output "ci_role_name" {
  value = aws_iam_role.ci_role.name
}

output "ci_role_arn" {
  value = aws_iam_role.ci_role.arn
}
