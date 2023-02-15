provider "grafana" {
  url  = var.grafana_endpoint_url
  auth = var.grafana_api_key
}


locals {
  default_dashboards = formatlist("${path.module}/%s", fileset(path.module, "src/*.json"))
}

resource "grafana_data_source" "amp" {
  type       = "prometheus"
  name       = var.eks_cluster_id
  is_default = true
  url        = var.prometheus_endpoint

  json_data {
    http_method     = "GET"
    sigv4_auth      = true
    sigv4_auth_type = "workspace-iam-role"
    sigv4_region    = var.prometheus_region
  }
}

resource "grafana_dashboard" "common" {
  for_each = setunion(local.default_dashboards, toset(var.app_charts))

  config_json = file(each.key)
}
