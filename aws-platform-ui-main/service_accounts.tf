module "prometheus_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  component      = "mon"

  oidc_provider_name = module.eks_vpc.oidc_provider_name
  oidc_provider_arn  = module.eks_vpc.oidc_provider_arn
  service_account    = "prometheus"
  k8s_namespace      = "prometheus"
  add_policy         = true
  policy             = data.aws_iam_policy_document.mon_prometheus.json
  id                 = random_string.prometheus.result

  providers = {
    aws = aws
  }
}

output "prometheus_service_account_role_arn" {
  value = module.prometheus_service_account_iam_role.arn
}

data "aws_iam_policy_document" "mon_prometheus" {
  statement {
    sid = "ApsIngest"

    actions = [
      "aps:RemoteWrite",
      "aps:GetSeries",
      "aps:GetLabels",
      "aps:GetMetricMetadata",
    ]

    resources = [aws_prometheus_workspace.k8s.arn]
  }
}
