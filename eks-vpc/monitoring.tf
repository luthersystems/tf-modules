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

resource "aws_prometheus_rule_group_namespace" "alert_rules" {
  count = var.monitoring ? 1 : 0

  name         = "alert-rules"
  workspace_id = aws_prometheus_workspace.k8s[0].id
  data         = <<EOT
groups:
  - name: service
    rules:
    - alert: LowDataVolumeSpace
      # used > 80%
      expr: (kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes) < 0.2
      for: 5m
      labels:
        project: "${var.luther_project}"
        environment: "${var.luther_env}"
        severity: page
      annotations:
        summary: "Service data volume usage above 80%"
    - alert: LowRootVolumeSpace
      # used > 80%
      expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.2
      for: 1m
      labels:
        project: "${var.luther_project}"
        environment: "${var.luther_env}"
        severity: page
      annotations:
        summary: "Instance(s) root volume usage above 80%"
    - alert: LowInstanceMemory
      # used > 80%
      expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) < 0.2
      for: 1m
      labels:
        project: "${var.luther_project}"
        environment: "${var.luther_env}"
        severity: page
      annotations:
        summary: "Instance(s) memory usage above 80%"
    - alert: ServiceDown
      expr: up != 1
      for: 2m
      labels:
        project: "${var.luther_project}"
        environment: "${var.luther_env}"
        severity: page
      annotations:
        summary: "Service(s) could not be scraped"
EOT
}

data "aws_iam_policy_document" "alerts_publish" {

  statement {
    sid = "Allow_Publish_Alarms"

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["aps.${data.aws_partition.current.dns_suffix}"]
    }

    actions = [
      "sns:Publish",
      "sns:GetTopicAttributes",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [var.aws_account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_prometheus_workspace.k8s[0].arn]
    }

    resources = [aws_sns_topic.alerts[0].arn]
  }
}

# TODO: slack alert lambda

resource "aws_sns_topic" "alerts" {
  count = var.monitoring ? 1 : 0

  name = module.luthername_prometheus.name
}

resource "aws_sns_topic_policy" "alerts" {
  count = var.monitoring ? 1 : 0

  arn    = aws_sns_topic.alerts[0].arn
  policy = data.aws_iam_policy_document.alerts_publish.json
}

resource "aws_prometheus_alert_manager_definition" "alerts" {
  count = var.monitoring ? 1 : 0

  workspace_id = aws_prometheus_workspace.k8s[0].id
  definition   = <<EOT
template_files:
  slack.luther.text.tmpl: !unsafe |
    {{ define "slack.luther.text" -}}
    {{ with $data := . -}}

    {{ if eq .Status "firing" -}}
    <!channel>: :scream_cat: {{len .Alerts.Firing}} active alerts in the group{{range .Alerts.Firing}} :fire:{{end}}
    {{- else -}}
    :disappointed_relieved: All alerts in the group are resolved
    {{- end }}

    {{- range $ann := .CommonAnnotations.SortedPairs }}
    - *{{.Name}}*: {{.Value}}
    {{- end }}
    {{- if gt (len .Alerts) 1 }}
    {{- range $alert := .Alerts }}
    {{ if eq .Status "firing" }}:fire:{{ else }}:ok_hand:{{ end }} {{(.Labels.Remove $data.CommonLabels.Names).Values | join " "}}
    {{- range $ann := (.Annotations.Remove $data.CommonAnnotations.Names).SortedPairs}}
    - *{{.Name}}*: {{.Value}}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- end }}
  slack.luther.title.tmpl: !unsafe |
    {{ define "slack.luther.title" -}}
    [{{ .GroupLabels.project }}-{{ .GroupLabels.environment }}]
    {{- range .GroupLabels.SortedPairs }}
    {{- if or (eq .Name "project") (eq .Name "environment") }}{{ else }} {{ .Value }}{{ end }}{{ end }}
    {{- if gt (len .CommonLabels) (len .GroupLabels)}} ({{(.CommonLabels.Remove .GroupLabels.Names).Values | join " "}}){{end}}
    {{- end }}
alertmanager_config: |
  global:
  templates:
    - 'slack.luther.text.tmpl'
    - 'slack.luther.title.tmpl'
  route:
    receiver: slack_alerts
    group_wait: 15s
    group_interval: 5m
    group_by:
      - project
      - environment
      - alertname
  receivers:
    - name: slack_alerts
      sns_configs:
      - topic_arn: ${aws_sns_topic.alerts[0].arn}
        sigv4:
          region: ${var.aws_region}
        message: '{% raw %}{{ template "slack.luther.text" . }}{% endraw %}'
        subject: '{% raw %}{{ template "slack.luther.title" . }}{% endraw %}'
        attributes:
          key: severity
          value: SEV2
EOT
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

provider "aws" {
  alias = "us-east-1"
}

module "grafana_frontend_url" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "mon"
  resource       = ""
}

locals {
  human_grafana_domain = var.use_human_grafana_domain ? "${module.grafana_frontend_url.name}.${var.domain}" : ""
}

module "grafana_frontend" {
  count = var.monitoring && var.use_human_grafana_domain ? 1 : 0

  source            = "../aws-cf-reverse-proxy"
  luther_env        = var.luther_env
  luther_project    = var.luther_project
  app_naked_domain  = var.domain
  app_target_domain = local.human_grafana_domain
  origin_url        = aws_grafana_workspace.grafana[0].endpoint

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }
}

output "human_grafana_domain" {
  value = local.human_grafana_domain
}
