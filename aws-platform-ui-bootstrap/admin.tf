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

  # Optional deny-only cap (sandbox-infrastructure-template#147). Defaults to
  # null — identical to today's behavior — unless the caller passes
  # permissions_boundary_arn.
  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null

  tags = module.luthername_admin_role.tags

  lifecycle {
    ignore_changes = [managed_policy_arns]
  }
}

# Customer-managed deploy policy — created only when the caller supplies a
# policy body (sandbox-infrastructure-template#147: replacing the
# AdministratorAccess attachment on the durable terraform role with a scoped
# InsideOutWrite policy).
resource "aws_iam_policy" "deploy" {
  count = var.deploy_policy_json != "" ? 1 : 0

  name        = "${var.admin_role_name}-deploy"
  description = "Customer-managed deploy policy for ${var.admin_role_name}, attached in place of AdministratorAccess"
  policy      = var.deploy_policy_json

  tags = module.luthername_admin_role.tags
}

# NOTE: deliberately NOT count-gated. Keeping this resource unconditional and
# swapping only its policy_arn preserves the resource address
# `aws_iam_role_policy_attachment.admin` for every existing consumer. Gating it
# with count would re-address it to `...admin[0]`, planning a destroy+create of
# the SAME (role, AdministratorAccess) pair whose apply order is not
# guaranteed — the detach can land after the re-attach and leave the role with
# no policy at all.
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = var.deploy_policy_json != "" ? aws_iam_policy.deploy[0].arn : "arn:aws:iam::aws:policy/AdministratorAccess"
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
