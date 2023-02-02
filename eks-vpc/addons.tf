output "aws_iam_role_eks_node_sa_arn" {
  value = module.eks_node_service_account_iam_role.arn
}

output "aws_iam_role_eks_node_sa" {
  value = module.eks_node_service_account_iam_role.name
}

resource "random_string" "eks_node" {
  length  = 4
  upper   = false
  special = false
}

module "eks_node_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "k8s"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "aws-node"
  k8s_namespace      = "kube-system"
  id                 = random_string.eks_node.result

  providers = {
    aws = aws
  }
}

resource "random_string" "ebs_csi" {
  length  = 4
  upper   = false
  special = false
}

module "ebs_csi_controller_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "k8s"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "ebs-csi-controller-sa"
  k8s_namespace      = "kube-system"
  id                 = random_string.ebs_csi.result

  providers = {
    aws = aws
  }
}

module "ebs_csi_node_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "k8s"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
  service_account    = "ebs-csi-node-sa"
  k8s_namespace      = "kube-system"
  id                 = random_string.ebs_csi.result

  providers = {
    aws = aws
  }
}


data "aws_iam_policy_document" "kms_ebs" {
  statement {
    effect = "Allow"

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]

    resources = [data.aws_kms_key.volumes.arn]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [data.aws_kms_key.volumes.arn]
  }
}

resource "aws_iam_role_policy_attachment" "ebs_controllerr_csi_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = module.ebs_csi_controller_service_account_iam_role.name
}

resource "aws_iam_role_policy" "ebs_controller_csi_kms" {
  role   = module.ebs_csi_controller_service_account_iam_role.name
  policy = data.aws_iam_policy_document.kms_ebs.json
}

resource "time_sleep" "k8s_ready_wait" {
  depends_on = [aws_autoscaling_group.eks_worker, aws_eks_node_group.eks_worker]

  create_duration = local.managed_nodes ? "1s" : "3m"
}

resource "aws_eks_addon" "vpc_cni" {
  count = local.cni_addon ? 1 : 0

  cluster_name             = aws_eks_cluster.app.name
  addon_name               = "vpc-cni"
  addon_version            = var.cni_addon_version[local.kubernetes_version]
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = module.eks_node_service_account_iam_role.arn
}

resource "aws_eks_addon" "kube_proxy" {
  count = local.kubeproxy_addon ? 1 : 0

  cluster_name      = aws_eks_cluster.app.name
  addon_name        = "kube-proxy"
  addon_version     = var.kubeproxy_addon_version[local.kubernetes_version]
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  count = local.coredns_addon ? 1 : 0

  cluster_name      = aws_eks_cluster.app.name
  addon_name        = "coredns"
  addon_version     = var.coredns_addon_version[local.kubernetes_version]
  resolve_conflicts = "OVERWRITE"

  depends_on = [time_sleep.k8s_ready_wait]
}

resource "aws_eks_addon" "ebs-csi" {
  count = local.csi_addon ? 1 : 0

  cluster_name             = aws_eks_cluster.app.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.csi_addon_version[local.kubernetes_version]
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = module.ebs_csi_controller_service_account_iam_role.arn

  depends_on = [time_sleep.k8s_ready_wait]
}
