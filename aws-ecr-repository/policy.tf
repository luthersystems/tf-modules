locals {
  ecr_actions_ro = [
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:BatchCheckLayerAvailability",
    "ecr:DescribeRepositories",
    "ecr:DescribeImages",
    "ecr:ListImages",
  ]

  ecr_actions_rw = [
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

  # NOTE:  If both ro_principals and rw_principals are empty then the following
  # is not a valid policy document because it has an empty list of principals but
  # that is OK because in that case no policy will be attached to the repository.
  policy = length(var.ro_principals) == 0 ? data.aws_iam_policy_document.rw.json : length(var.rw_principals) == 0 ? data.aws_iam_policy_document.ro.json : data.aws_iam_policy_document.rorw.json
}

# policy that has only readonly principals
data "aws_iam_policy_document" "ro" {
  statement {
    sid     = "readonlyAccess"
    effect  = "Allow"
    actions = local.ecr_actions_ro

    principals {
      type        = "AWS"
      identifiers = var.ro_principals
    }
  }
}

# policy that has only readwrite principals
data "aws_iam_policy_document" "rw" {
  statement {
    sid     = "readwriteAccess"
    effect  = "Allow"
    actions = local.ecr_actions_rw

    principals {
      type        = "AWS"
      identifiers = var.rw_principals
    }
  }
}

# policy that has both readonly and readwrite principals
data "aws_iam_policy_document" "rorw" {
  statement {
    sid     = "readonlyAccess"
    effect  = "Allow"
    actions = local.ecr_actions_ro

    principals {
      type        = "AWS"
      identifiers = var.ro_principals
    }
  }

  statement {
    sid     = "readwriteAccess"
    effect  = "Allow"
    actions = local.ecr_actions_rw

    principals {
      type        = "AWS"
      identifiers = var.rw_principals
    }
  }
}
