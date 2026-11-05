# EBS snapshot access for the env-admin role. Ansible runs as this role
# (mars, kubectl_env). A playbook can then read the cluster's EBS volumes,
# tag a volume with KubernetesCluster=<cluster> (the tag that the DLM policy
# of aws-platform-ui-main selects), and take an on-demand snapshot before a
# step that cannot be undone. Example: ui-infrastructure
# ansible/fabric_snapshot_volumes.yaml. The role cannot delete a snapshot or
# a volume, and cannot set another tag key on a volume.
variable "env_admin_ebs_snapshots" {
  type        = bool
  default     = true
  description = "Let the env-admin role read and tag EBS volumes and take EBS snapshots (has_env_admin must be true)"
}

locals {
  env_admin_ebs_snapshots = var.has_env_admin && var.env_admin_ebs_snapshots
}

data "aws_iam_policy_document" "env_admin_ebs_snapshots" {
  statement {
    sid       = "ReadVolumesAndSnapshots"
    actions   = ["ec2:DescribeVolumes", "ec2:DescribeSnapshots"]
    resources = ["*"]
  }

  statement {
    sid     = "CreateSnapshot"
    actions = ["ec2:CreateSnapshot"]
    resources = [
      "arn:aws:ec2:${local.region}:${local.account_id}:volume/*",
      "arn:aws:ec2:${local.region}::snapshot/*",
    ]
  }

  # Tags on a new snapshot only.
  statement {
    sid       = "TagNewSnapshots"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${local.region}::snapshot/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSnapshot"]
    }
  }

  # Only the KubernetesCluster tag on a volume.
  statement {
    sid       = "TagVolumesWithCluster"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:${local.region}:${local.account_id}:volume/*"]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["KubernetesCluster"]
    }
  }
}

resource "aws_iam_policy" "env_admin_ebs_snapshots" {
  count = local.env_admin_ebs_snapshots ? 1 : 0

  name        = "${aws_iam_role.env_admin_role[0].name}-ebs-snapshots"
  description = "Read and tag EBS volumes and take EBS snapshots"
  policy      = data.aws_iam_policy_document.env_admin_ebs_snapshots.json

  tags = module.luthername_env_admin_role.tags
}

resource "aws_iam_role_policy_attachment" "env_admin_ebs_snapshots" {
  count = local.env_admin_ebs_snapshots ? 1 : 0

  role       = aws_iam_role.env_admin_role[0].name
  policy_arn = aws_iam_policy.env_admin_ebs_snapshots[0].arn
}
