module "luthername_env_admin_role" {
  source         = "../luthername"
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
  count = var.has_env_admin ? 1 : 0

  name               = "${module.luthername_env_admin_role.name}-role"
  description        = "Provides environment Admin level access"
  assume_role_policy = data.aws_iam_policy_document.env_admin_assume_role.json

  tags = module.luthername_env_admin_role.tags
}

output "env_admin_role_name" {
  value = try(aws_iam_role.env_admin_role[0].name, null)
}

output "env_admin_role_arn" {
  value = try(aws_iam_role.env_admin_role[0].arn, null)
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

locals {
  # TODO generalize this by creating a new var that is an array of ojects with these values, and construct
  # the sub strs from these objects
  ci_github_sub_strs = [for sub in var.ci_github_repos : "repo:${sub.org}/${sub.repo}:environment:${sub.env}"]
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
        values   = local.ci_github_sub_strs
      }
    }
  }
}

module "luthername_ci_role" {
  source         = "../luthername"
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

data "aws_iam_policy_document" "ecr_push_ci" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
      "ecr:ListImages",
      "ecr:BatchDeleteImage",
    ]
    resources = var.ci_ecr_push_arns
  }
}

resource "aws_iam_policy" "ecr_push_ci" {
  count = length(var.ci_ecr_push_arns) == 0 ? 0 : 1

  name   = "${module.luthername_ci_role.name}-ecr-rw"
  path   = "/"
  policy = data.aws_iam_policy_document.ecr_push_ci.json
}

resource "aws_iam_role_policy_attachment" "ecr_push_ci" {
  count = length(var.ci_ecr_push_arns) == 0 ? 0 : 1

  role       = aws_iam_role.ci_role.name
  policy_arn = aws_iam_policy.ecr_push_ci[0].arn
}
