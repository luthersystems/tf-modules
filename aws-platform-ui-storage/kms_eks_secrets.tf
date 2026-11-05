# A KMS key for EKS secrets envelope encryption (tf-modules#84), for
# aws-platform-ui-main's eks_secrets_kms_key_arn.
#
# Why here and not in aws-platform-ui-main: EKS cannot change or remove the
# key once secrets encryption is on, and every secret the cluster holds is
# unreadable without it. So the key must outlive the cluster. This module
# outlives it (it holds the env's buckets and keys), and a cluster rebuilt
# in the same region from aws-platform-ui-main can take the same key again.
# The key is single-region: EKS needs a key in the cluster's own region, so
# a cluster in region_dr needs its own key.
#
# Why its own key and not kms_key_main: this one encrypts only cluster
# secrets, so its key usage and CloudTrail decrypt events say only that, and
# its access stays separate from the S3 and EBS access on the main key.
#
# The key policy delegates to IAM (the account root statement); eks-vpc
# grants the cluster role the actions EKS needs on this key.
#
# No prevent_destroy: it would also block tearing down the whole env, when
# the cluster goes too. The guard is that the key is opt-in, the variable
# warns, and the 30-day delete window lets an operator cancel a mistake.

module "luthername_kms_key_eks_secrets" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "storage"
  subcomponent   = "eks"
  resource       = "kms"
  id             = random_string.kms_key_main.result
}

resource "aws_kms_key" "eks_secrets" {
  count = var.eks_secrets_kms_key ? 1 : 0

  description = "EKS secrets envelope encryption"
  policy      = data.aws_iam_policy_document.kms_key_eks_secrets.json

  # Rotation keeps the same key ARN, so EKS (which cannot change keys) is
  # unaffected; the longest delete window gives the most time to cancel a
  # deletion that would make the cluster's secrets unreadable.
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = module.luthername_kms_key_eks_secrets.tags
}

data "aws_iam_policy_document" "kms_key_eks_secrets" {
  statement {
    sid = "Enable IAM User Permissions"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_alias" "eks_secrets" {
  count = var.eks_secrets_kms_key ? 1 : 0

  name          = "alias/${module.luthername_kms_key_eks_secrets.name}"
  target_key_id = aws_kms_key.eks_secrets[0].key_id
}

output "kms_key_eks_secrets_arn" {
  description = "ARN of the EKS secrets key, for aws-platform-ui-main's eks_secrets_kms_key_arn. Empty when eks_secrets_kms_key is false."
  value       = join("", aws_kms_key.eks_secrets[*].arn)
}

output "kms_alias_eks_secrets_arn" {
  description = "ARN of the EKS secrets key's alias. Empty when eks_secrets_kms_key is false."
  value       = join("", aws_kms_alias.eks_secrets[*].arn)
}
