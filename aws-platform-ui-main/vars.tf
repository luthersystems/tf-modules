variable "luther_env" {
  type = string
}

variable "domain" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "env_static_s3_bucket" {
  type = string
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
  type = list(string)
  default = [
    # "arn:aws:kms:eu-west-2:967058059066:alias/common-ln-common-luther-storage-kms-umaq",
    "arn:aws:kms:eu-west-2:967058059066:key/4cf1dd96-7fd0-4d76-8cc6-4d991d6b27cf",
    # "arn:aws:kms:eu-west-2:967058059066:alias/common-ln-common-luther-external-kms-ehpz",
    "arn:aws:kms:eu-west-2:967058059066:key/078b9b79-8ae6-4d50-9143-1cc3228dd232",
  ]
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

variable "use_human_grafana_domain" {
  default = false
}

variable "monitoring" {
  default = true
}
