module "luthername_k8s_admin" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "k8s-admin"
}

data "aws_iam_policy_document" "eks_kubeconfig_permissions" {
  statement {
    actions = [
      "eks:DescribeCluster"
    ]

    resources = [
      aws_eks_cluster.app.arn
    ]
  }
}

resource "aws_iam_policy" "eks_kubeconfig_policy" {
  count = var.has_alt_admin_role ? 1 : 0

  name   = module.luthername_k8s_admin.name
  policy = data.aws_iam_policy_document.eks_kubeconfig_permissions.json

  tags = module.luthername_k8s_admin.tags
}

locals {
  k8s_alt_admin_role_arn = var.has_alt_admin_role ? var.k8s_alt_admin_role_arn : ""
  k8s_alt_admin_role     = element(split("/", local.k8s_alt_admin_role_arn), 1)
}

resource "aws_iam_role_policy_attachment" "alt_admin_eks_kubeconfig_policy_attachment" {
  count = var.has_alt_admin_role ? 1 : 0

  role       = local.k8s_alt_admin_role
  policy_arn = aws_iam_policy.eks_kubeconfig_policy[0].arn
}
