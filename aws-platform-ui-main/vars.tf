variable "luther_env" {
  type = string
}

variable "monitoring_human_domain" {
  default = ""
}

variable "kubernetes_version" {
  type = string
}

variable "env_static_s3_bucket_arn" {
  default = ""
}

variable "storage_kms_key_arn" {
  type = string
}

variable "eks_worker_count" {
  default = 1
}

variable "eks_worker_spot_price" {
  default = ""
}

variable "eks_worker_instance_type" {
  type    = string
  default = "t3a.large"
}

variable "luther_project" {
  type    = string
  default = "plt"
}

variable "luther_project_name" {
  type    = string
  default = "platform"
}

variable "org_name" {
  type    = string
  default = "luther"
}

variable "shared_asset_kms_key_arns" {
  type    = list(string)
  default = []
}

variable "additional_ansible_facts" {
  type    = map(string)
  default = {}
}

variable "ansible_relative_path" {
  default = "../ansible"
}

variable "grafana_saml_admin_role_values" {
  type    = list(string)
  default = []
}

variable "grafana_saml_role_assertion" {
  default = ""
}

variable "grafana_saml_metadata_xml" {
  default = ""
}

variable "monitoring" {
  default = false
}

variable "preserve_coredns" {
  default = true
}

variable "slack_alerts_web_hook_url_secret" {
  default = ""
}

variable "worker_volume_type" {
  default = "gp3"
}

variable "enable_csi_vol_mod" {
  default = false
}

