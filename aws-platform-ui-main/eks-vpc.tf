data "aws_ami" "ubuntu" {
  // Canonical
  owners      = ["099720109477"]
  most_recent = true
  name_regex  = "^ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-\\d{8}$"
}

module "eks_vpc" {
  source = "../eks-vpc"

  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  component      = "main"

  kubernetes_version   = var.kubernetes_version
  worker_instance_type = var.eks_worker_instance_type

  aws_account_id = local.account_id

  use_bastion = false

  domain = var.domain

  aws_kms_key_arns       = concat([data.aws_kms_key.storage.arn], var.shared_asset_kms_key_arns)
  volumes_aws_kms_key_id = data.aws_kms_key.storage.id

  autoscaling_desired = var.eks_worker_count

  storage_s3_bucket_arn = data.aws_s3_bucket.env_static.arn

  storage_s3_key_prefixes = [
    "${var.luther_env}/*",
    "phyla/*",
  ]

  public_api = true

  providers = {
    aws.cloudwatch = aws
    aws            = aws
    null           = null
    local          = local
    external       = external
    tls            = tls
  }
}

output "eks_cluster_name" {
  value = module.eks_vpc.aws_eks_cluster_name
}

output "eks_cluster_arn" {
  value = module.eks_vpc.aws_eks_cluster_arn
}

output "oidc_provider_name" {
  value = module.eks_vpc.oidc_provider_name
}

output "oidc_provider_arn" {
  value = module.eks_vpc.oidc_provider_arn
}

output "aws_cloudwatch_log_group" {
  value = "${module.eks_vpc.aws_cloudwatch_log_group}:*"
}

output "eks_worker_role_arn" {
  value = module.eks_vpc.aws_iam_role_eks_worker_arn
}

data "aws_iam_role" "admin" {
  name = "admin"
}

module "luthername_role_policy_app_kms" {
  source = "../luthername"

  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = "app"
  resource       = "iampolicy"
  subcomponent   = "kms"
}

resource "aws_iam_role_policy" "app_kms" {
  name   = module.luthername_role_policy_app_kms.name
  role   = module.eks_vpc.aws_iam_role_eks_worker
  policy = data.aws_iam_policy_document.app_kms.json
}

data "aws_iam_policy_document" "app_kms" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "ec2.${local.region}.amazonaws.com",
        "s3.${local.region}.amazonaws.com",
      ]

    }

    resources = [data.aws_kms_key.storage.arn]
  }
}

resource "aws_iam_role_policy" "worker_ecr_mars_ro" {
  name   = "ecr-mars-ro"
  role   = module.eks_vpc.aws_iam_role_eks_worker
  policy = data.aws_iam_policy_document.worker_ecr_mars_ro.json
}

locals {
  ecr_actions_ro = [
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:BatchCheckLayerAvailability",
    "ecr:DescribeRepositories",
    "ecr:DescribeImages",
    "ecr:ListImages",
  ]
}

data "aws_iam_policy_document" "worker_ecr_mars_ro" {
  statement {
    sid     = "readonlyAccess"
    effect  = "Allow"
    actions = local.ecr_actions_ro

    resources = ["arn:aws:ecr:eu-west-2:967058059066:repository/luthersystems/mars"]
  }
}
