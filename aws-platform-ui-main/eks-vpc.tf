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

  domain = var.domain

  aws_kms_key_arns       = concat([data.aws_kms_key.storage.arn], var.shared_asset_kms_key_arns)
  volumes_aws_kms_key_id = data.aws_kms_key.storage.id

  autoscaling_desired = var.eks_worker_count

  storage_s3_bucket_arn = data.aws_s3_bucket.env_static.arn

  spot_price = var.eks_worker_spot_price

  public_api = true

  disable_cni_node_role = var.disable_cni_node_role
  disable_csi_node_role = var.disable_csi_node_role
  disable_alb_node_role = var.disable_alb_node_role

  cni_addon     = var.cni_addon
  csi_addon     = var.csi_addon
  coredns_addon = var.coredns_addon

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

output "eks_node_sa_role_arn" {
  value = module.eks_vpc.aws_iam_role_eks_node_sa_arn
}

data "aws_iam_role" "admin" {
  name = "admin"
}
