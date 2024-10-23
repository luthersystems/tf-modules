module "eks_vpc" {
  source = "../eks-vpc"

  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  component      = "main"

  kubernetes_version   = var.kubernetes_version
  worker_instance_type = var.eks_worker_instance_type

  aws_account_id = local.account_id

  human_domain = ""

  aws_kms_key_arns       = concat([data.aws_kms_key.storage.arn], var.shared_asset_kms_key_arns)
  volumes_aws_kms_key_id = data.aws_kms_key.storage.id

  autoscaling_desired = var.eks_worker_count

  storage_s3_bucket_arn = var.env_static_s3_bucket_arn

  spot_price = var.eks_worker_spot_price

  public_api = true

  monitoring                     = var.monitoring
  logs                           = var.logs
  grafana_saml_admin_role_values = var.grafana_saml_admin_role_values
  grafana_saml_role_assertion    = var.grafana_saml_role_assertion
  grafana_saml_metadata_xml      = var.grafana_saml_metadata_xml
  common_static_s3_bucket_arn    = var.common_static_s3_bucket_arn
  common_external_s3_bucket_arn  = var.common_external_s3_bucket_arn
  root_volume_size_gb            = var.eks_root_volume_size_gb

  preserve_coredns = var.preserve_coredns

  slack_alerts_web_hook_url_secret = var.slack_alerts_web_hook_url_secret

  worker_volume_type = var.worker_volume_type

  awslogs_driver = false

  enable_csi_vol_mod = var.enable_csi_vol_mod

  disable_s3_node_role = true

  has_alt_admin_role     = var.has_alt_admin_role
  k8s_alt_admin_role_arn = var.k8s_alt_admin_role_arn

  custom_instance_userdata         = var.custom_instance_userdata
  custom_instance_userdata_version = var.custom_instance_userdata_version

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
    null          = null
    local         = local
    external      = external
    tls           = tls
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

output "grafana_api_key" {
  value     = module.eks_vpc.grafana_api_key
  sensitive = true
}

output "prometheus_endpoint" {
  value = module.eks_vpc.prometheus_endpoint
}

output "grafana_endpoint_url" {
  value = module.eks_vpc.grafana_endpoint_url
}

output "grafana_human_url" {
  value = module.eks_vpc.grafana_human_url
}

output "grafana_saml_acs_url" {
  value = module.eks_vpc.grafana_saml_acs_url
}

output "grafana_saml_entity_id" {
  value = module.eks_vpc.grafana_saml_entity_id
}

output "grafana_saml_start_url" {
  value = module.eks_vpc.grafana_saml_start_url
}
