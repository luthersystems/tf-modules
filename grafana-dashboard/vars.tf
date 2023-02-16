variable "grafana_endpoint_url" {
  default = ""
}

variable "grafana_api_key" {
  default = ""
}

variable "eks_cluster_id" {
  default = ""
}

variable "prometheus_endpoint" {
  default = ""
}

variable "prometheus_region" {
  default = ""
}

variable "app_charts" {
  type    = list(string)
  default = []
}
