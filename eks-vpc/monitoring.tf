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
  count = local.monitoring ? 1 : 0

  alias = module.luthername_prometheus.name
  tags  = module.luthername_prometheus.tags
}

locals {
  data_volume_space_used_percentage = format("%.0f", (1 - var.data_volume_space_threshold) * 100)
  root_volume_space_used_percentage = format("%.0f", (1 - var.root_volume_space_threshold) * 100)
  instance_memory_used_percentage   = format("%.0f", (1 - var.instance_memory_threshold) * 100)
}

locals {
  default_alert_rules = <<EOT
groups:
  - name: service
    rules:
    - alert: LowDataVolumeSpace
      expr: (kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes) < ${var.data_volume_space_threshold}
      for: 5m
      labels:
        project: "${var.luther_project}"
        environment: "${var.luther_env}"
        severity: page
      annotations:
        summary: "Service data volume usage above ${local.data_volume_space_used_percentage}%"
    - alert: LowRootVolumeSpace
      expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < ${var.root_volume_space_threshold}
      for: 1m
      labels:
        project: "${var.luther_project}"
        environment: "${var.luther_env}"
        severity: page
      annotations:
        summary: "Instance(s) root volume usage above ${local.root_volume_space_used_percentage}%"
    - alert: LowInstanceMemory
      expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) < ${var.instance_memory_threshold}
      for: 1m
      labels:
        project: "${var.luther_project}"
        environment: "${var.luther_env}"
        severity: page
      annotations:
        summary: "Instance(s) memory usage above ${local.instance_memory_used_percentage}%"
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

resource "aws_prometheus_rule_group_namespace" "alert_rules" {
  count = local.alerts ? 1 : 0

  name         = "alert-rules"
  workspace_id = aws_prometheus_workspace.k8s[0].id
  data         = var.alert_rules != "" ? var.alert_rules : local.default_alert_rules
}

data "aws_iam_policy_document" "alerts_publish" {
  count = local.alerts ? 1 : 0

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

module "luthername_slack_alerts_web_hook_url_secret" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "mon"
  resource       = "slack-url-secret"
}

locals {
  slack_secret_kms_arn = var.volumes_aws_kms_key_id
}

resource "aws_secretsmanager_secret" "slack_alerts_web_hook_url" {
  count = local.alerts ? 1 : 0

  name       = module.luthername_slack_alerts_web_hook_url_secret.name
  kms_key_id = local.slack_secret_kms_arn

  tags = module.luthername_slack_alerts_web_hook_url_secret.tags
}

resource "aws_secretsmanager_secret_version" "slack_alerts_web_hook_url_secret" {
  count = local.alerts ? 1 : 0

  secret_id     = aws_secretsmanager_secret.slack_alerts_web_hook_url[0].id
  secret_string = var.slack_alerts_web_hook_url_secret

  lifecycle {
    ignore_changes = [secret_string]
  }
}

locals {
  alerts = var.monitoring && var.slack_alerts_web_hook_url_secret != ""
}

module "slack_sns_alert_lambda" {
  count = local.alerts ? 1 : 0

  source = "../aws-lambda-sns-slack-alerts"

  aws_region              = var.aws_region
  luther_project          = var.luther_project
  luther_env              = var.luther_env
  org_name                = "luther"
  web_hook_url_secret_arn = aws_secretsmanager_secret.slack_alerts_web_hook_url[0].arn
  secret_kms_key_id       = local.slack_secret_kms_arn
  sns_topic_arn           = aws_sns_topic.alerts[0].arn
}

resource "aws_sns_topic" "alerts" {
  count = local.alerts ? 1 : 0

  name = module.luthername_prometheus.name
}

resource "aws_sns_topic_policy" "alerts" {
  count = local.alerts ? 1 : 0

  arn    = aws_sns_topic.alerts[0].arn
  policy = data.aws_iam_policy_document.alerts_publish[0].json
}

resource "aws_prometheus_alert_manager_definition" "alerts" {
  count = local.alerts ? 1 : 0

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
        message: '{{ template "slack.luther.text" . }}'
        subject: '{{ template "slack.luther.title" . }}'
        attributes:
          key: severity
          value: SEV2
EOT
}

output "prometheus_workspace_id" {
  value = try(aws_prometheus_workspace.k8s[0].id, null)
}

output "prometheus_endpoint" {
  value = try(aws_prometheus_workspace.k8s[0].prometheus_endpoint, null)
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
  count = local.monitoring ? 1 : 0

  name                     = module.luthername_grafana.name
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  data_sources             = ["PROMETHEUS"]
  grafana_version          = "9.4"
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
  count = local.monitoring ? 1 : 0

  name   = "${module.luthername_grafana.name}-ingest"
  role   = aws_iam_role.grafana.id
  policy = data.aws_iam_policy_document.grafana[0].json
}

data "aws_iam_policy_document" "grafana" {
  count = local.monitoring ? 1 : 0

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
      "aps:ListRules",
      "aps:ListAlertManagerSilences",
      "aps:ListAlertManagerAlerts",
      "aps:GetAlertManagerStatus",
      "aps:ListAlertManagerAlertGroups",
      "aps:PutAlertManagerSilences",
      "aps:DeleteAlertManagerSilence",
      "aps:ListWorkspaces",
    ]

    resources = try([aws_prometheus_workspace.k8s[0].arn], [])
  }
}

resource "aws_grafana_workspace_saml_configuration" "grafana" {
  count = local.monitoring && var.grafana_saml_metadata_xml != "" ? 1 : 0

  editor_role_values = ["editor"]
  idp_metadata_xml   = var.grafana_saml_metadata_xml
  workspace_id       = aws_grafana_workspace.grafana[0].id
  admin_role_values  = var.grafana_saml_admin_role_values
  role_assertion     = var.grafana_saml_role_assertion
}

output "grafana_endpoint" {
  value = try(aws_grafana_workspace.grafana[0].endpoint, "")
}

resource "time_static" "api_key_create_date" {}

resource "aws_grafana_workspace_api_key" "grafana" {
  count = local.monitoring ? 1 : 0

  # this works most of the time, but could fail in a month with 31 days
  key_name        = format("tf-%s", formatdate("YYYY-MM", time_static.api_key_create_date.rfc3339))
  key_role        = "ADMIN"
  seconds_to_live = 60 * 60 * 24 * 30 # max is 30 days
  workspace_id    = aws_grafana_workspace.grafana[0].id
}

output "grafana_api_key" {
  value     = try(aws_grafana_workspace_api_key.grafana[0].key, null)
  sensitive = true
}

module "prometheus_service_account_iam_role" {
  count = local.monitoring ? 1 : 0

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
  policy             = data.aws_iam_policy_document.mon_prometheus[0].json
  id                 = random_string.prometheus.result

  providers = {
    aws = aws
  }
}

locals {
  prometheus_service_account_role_arn = try(module.prometheus_service_account_iam_role[0].arn, "")
}

output "prometheus_service_account_role_arn" {
  value = local.prometheus_service_account_role_arn
}

data "aws_iam_policy_document" "mon_prometheus" {
  count = local.monitoring ? 1 : 0

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

module "grafana_frontend_url" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = ""
  component      = "mon"
  resource       = ""
}

locals {
  grafana_endpoint     = try(aws_grafana_workspace.grafana[0].endpoint, null)
  grafana_human_domain = local.monitoring && var.human_domain != "" ? "${module.grafana_frontend_url.prefix}.${var.human_domain}" : null
  grafana_endpoint_url = try(format("https://%s", local.grafana_endpoint), "")
}

module "grafana_frontend" {
  count = local.grafana_human_domain != null ? 1 : 0

  source            = "../aws-cf-reverse-proxy"
  luther_env        = var.luther_env
  luther_project    = var.luther_project
  app_naked_domain  = var.human_domain
  app_target_domain = local.grafana_human_domain
  origin_url        = local.grafana_endpoint_url
  use_302           = true

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }
}

output "grafana_endpoint_url" {
  value = local.grafana_endpoint_url
}

output "grafana_human_url" {
  value = try(format("https://%s", local.grafana_human_domain), "")
}

output "grafana_saml_acs_url" {
  value = try(format("%s/saml/acs", local.grafana_endpoint_url), "")
}

output "grafana_saml_entity_id" {
  value = try(format("%s/saml/metadata", local.grafana_endpoint_url), "")
}

output "grafana_saml_start_url" {
  value = try(format("%s/login/saml", local.grafana_endpoint_url), "")
}

output "grafana_workspace_id" {
  value = try(aws_grafana_workspace.grafana[0].id, "")
}

locals {
  remote_prom_query_role_arn = local.monitoring ? var.remote_prom_query_role_arn : ""
}

data "aws_iam_policy_document" "prometheus_query_assume_role" {
  count = local.remote_prom_query_role_arn != "" ? 1 : 0

  statement {
    sid     = "PrometheusQueryAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.remote_prom_query_role_arn]
    }
  }
}

resource "aws_iam_role" "prometheus_query_role" {
  count = local.remote_prom_query_role_arn != "" ? 1 : 0

  name = "${module.luthername_prometheus.name}-query"

  assume_role_policy = data.aws_iam_policy_document.prometheus_query_assume_role[0].json
}

data "aws_iam_policy_document" "prometheus_query_policy" {
  count = var.remote_prom_query_role_arn != "" ? 1 : 0

  statement {
    sid = "PrometheusQueryMetrics"

    actions = [
      "aps:QueryMetrics"
    ]

    resources = try([aws_prometheus_workspace.k8s[0].arn], [])
  }
}

resource "aws_iam_policy" "prometheus_query_policy" {
  count = local.remote_prom_query_role_arn != "" ? 1 : 0

  name   = "${module.luthername_prometheus.name}-query-pol"
  policy = data.aws_iam_policy_document.prometheus_query_policy[0].json

}

resource "aws_iam_role_policy_attachment" "prometheus_query_role_attachment" {
  count = local.remote_prom_query_role_arn != "" ? 1 : 0

  role       = aws_iam_role.prometheus_query_role[0].name
  policy_arn = aws_iam_policy.prometheus_query_policy[0].arn
}

output "prometheus_query_role_arn" {
  value       = try(aws_iam_role.prometheus_query_role[0].arn, null)
  description = "The ARN of the Prometheus query role for remote access"
}
