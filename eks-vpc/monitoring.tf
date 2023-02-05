module "luthername_prometheus" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "mon"
  resource       = "prom"
  id             = random_string.prometheus.result
}

resource "random_string" "prometheus" {
  length  = 4
  upper   = false
  special = false
}

resource "aws_prometheus_workspace" "k8s" {
  count = var.monitoring ? 1 : 0

  alias = module.luthername_prometheus.name
  tags  = module.luthername_prometheus.tags
}

output "prometheus_workspace_id" {
  value = try(aws_prometheus_workspace.k8s[0].id, null)
}

resource "random_string" "grafana" {
  length  = 4
  upper   = false
  special = false
}

module "luthername_grafana" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "mon"
  resource       = "graf"
  id             = random_string.grafana.result
}

resource "aws_grafana_workspace" "grafana" {
  count = var.monitoring ? 1 : 0

  name                     = module.luthername_grafana.name
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  data_sources             = ["PROMETHEUS"]
  tags                     = module.luthername_grafana.tags
}

resource "aws_iam_role" "grafana" {
  name               = "${module.luthername_grafana.name}-assume"
  assume_role_policy = data.aws_iam_policy_document.grafana-assume.json
}

data "aws_iam_policy_document" "grafana-assume" {
  statement {
    sid     = "GrafanaAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["grafana.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role_policy" "grafana" {
  name   = "${module.luthername_grafana.name}-ingest"
  role   = aws_iam_role.grafana.id
  policy = data.aws_iam_policy_document.grafana.json
}

data "aws_iam_policy_document" "grafana" {
  statement {
    sid = "GrafanaList"

    actions = [
      "aps:ListWorkspaces",
    ]

    resources = ["*"]
  }

  statement {
    sid = "GrafanaIngest"

    actions = [
      "aps:DescribeWorkspace",
      "aps:QueryMetrics",
      "aps:GetLabels",
      "aps:GetSeries",
      "aps:GetMetricMetadata",
    ]

    resources = try([aws_prometheus_workspace.k8s[0].arn], [])
  }
}

resource "aws_grafana_workspace_saml_configuration" "grafana" {
  count = var.monitoring && var.grafana_saml_metadata_xml != "" ? 1 : 0

  editor_role_values = ["editor"]
  idp_metadata_xml   = var.grafana_saml_metadata_xml
  workspace_id       = aws_grafana_workspace.grafana[0].id
  admin_role_values  = var.grafana_saml_admin_role_values
  role_assertion     = var.grafana_saml_role_assertion
}

output "grafana_endpoint" {
  value = try(aws_grafana_workspace.grafana[0].endpoint, null)
}

module "prometheus_service_account_iam_role" {
  source = "../eks-service-account-iam-role"

  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  component      = "mon"

  oidc_provider_name = local.oidc_provider_name
  oidc_provider_arn  = local.oidc_provider_arn
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

    resources = try([aws_prometheus_workspace.k8s[0].arn], [])
  }
}
