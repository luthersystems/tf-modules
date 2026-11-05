locals {
  # The EBS CSI driver tags each volume it creates with
  # KubernetesCluster=<cluster> (csi_tag_cluster_id). A volume created before
  # that needs the tag added once, or DLM does not snapshot it.
  snapshot_tags = {
    KubernetesCluster = module.eks_vpc.aws_eks_cluster_name
  }
}

module "fabric_snapshots" {
  source = "../ebs-dlm-snapshots"

  count = var.enable_dlm_snapshots ? 1 : 0

  description    = "${module.eks_vpc.aws_eks_cluster_name} every ${var.snapshot_frequency_hours} hour fabric snapshots"
  target_tags    = local.snapshot_tags
  role_arn       = aws_iam_role.dlm_snapshots[0].arn
  luther_project = var.luther_project
  luther_env     = var.luther_env

  retain_count   = ceil(24 / var.snapshot_frequency_hours) * var.snapshot_retention_days
  interval_hours = var.snapshot_frequency_hours
  times          = ["01:00"]

  cross_region_settings = var.ebs_cross_region_settings

  providers = {
    aws = aws
  }
}

resource "aws_iam_role" "dlm_snapshots" {
  count = var.enable_dlm_snapshots ? 1 : 0

  # IAM role names are unique per account: name it after the cluster.
  name               = "${module.eks_vpc.aws_eks_cluster_name}-dlm"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "dlm_snapshots" {
  count = var.enable_dlm_snapshots ? 1 : 0

  role       = aws_iam_role.dlm_snapshots[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}
