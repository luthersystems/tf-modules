variable "luther_env" {
  type = string
}

variable "domain" {
  type    = string
  default = ""
}

variable "kubernetes_version" {
  type = string
}

variable "env_static_s3_bucket_arn" {
  type    = string
  default = ""
}

variable "storage_kms_key_arn" {
  type = string
}

variable "eks_worker_count" {
  type    = number
  default = 1
}

variable "eks_worker_spot_price" {
  type    = string
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

variable "shared_asset_kms_key_arns" {
  type    = list(string)
  default = []
}

variable "additional_ansible_facts" {
  type    = map(string)
  default = {}
}

variable "ansible_relative_path" {
  type    = string
  default = "../ansible"
}

variable "grafana_saml_admin_role_values" {
  type    = list(string)
  default = []
}

variable "grafana_saml_role_assertion" {
  type    = string
  default = ""
}

variable "grafana_saml_metadata_xml" {
  type    = string
  default = ""
}

variable "monitoring" {
  type    = bool
  default = false
}

variable "preserve_coredns" {
  type    = bool
  default = true
}

variable "slack_alerts_web_hook_url_secret" {
  type    = string
  default = ""
}

variable "worker_volume_type" {
  type    = string
  default = "gp3"
}

variable "enable_csi_vol_mod" {
  type    = bool
  default = true
}

variable "common_static_s3_bucket_arn" {
  type    = string
  default = ""
}

variable "common_external_s3_bucket_arn" {
  type    = string
  default = ""
}

variable "k8s_alt_admin_role_arn" {
  type    = string
  default = ""
}

variable "has_alt_admin_role" {
  type    = bool
  default = false
}

variable "logs" {
  type    = bool
  default = false
}

variable "custom_instance_userdata" {
  type    = string
  default = ""
}
