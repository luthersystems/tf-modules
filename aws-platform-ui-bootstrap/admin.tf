module "luthername_admin_role" {
  source         = "../luthername"
  luther_project = var.project
  aws_region     = local.region
  luther_env     = var.env
  org_name       = var.org_name
  component      = "admin"
  resource       = "role"
}

resource "aws_iam_role" "admin" {
  name               = var.admin_role_name
  description        = "Provides administrator level access"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = module.luthername_admin_role.tags

  lifecycle {
    ignore_changes = [managed_policy_arns]
  }
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid = "allowAdmin"

    principals {
      type        = "AWS"
      identifiers = var.admin_principals
    }

    actions = ["sts:AssumeRole"]
  }
}

output "admin_role" {
  value = aws_iam_role.admin.arn
}
