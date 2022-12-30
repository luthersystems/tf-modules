module "luthername_prometheus" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = local.region
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
  alias = module.luthername_prometheus.name
  tags  = module.luthername_prometheus.tags
}

output "prometheus_workspace_id" {
  value = aws_prometheus_workspace.k8s.id
}

resource "random_string" "grafana" {
  length  = 4
  upper   = false
  special = false
}

module "luthername_grafana" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "mon"
  resource       = "graf"
  id             = random_string.grafana.result
}

resource "aws_grafana_workspace" "grafana" {
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

    resources = [aws_prometheus_workspace.k8s.arn]
  }
}

resource "aws_grafana_workspace_saml_configuration" "grafana" {
  count = var.grafana_saml_metadata_xml != "" ? 1 : 0

  editor_role_values = ["editor"]
  idp_metadata_xml   = var.grafana_saml_metadata_xml
  workspace_id       = aws_grafana_workspace.grafana.id
  admin_role_values  = var.grafana_saml_admin_role_values
  role_assertion     = var.grafana_saml_role_assertion
}

output "grafana_endpoint" {
  value = aws_grafana_workspace.grafana.endpoint
}
