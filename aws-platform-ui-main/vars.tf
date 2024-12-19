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

variable "custom_instance_userdata_version" {
  type    = string
  default = ""
}

variable "eks_root_volume_size_gb" {
  type    = number
  default = 30
}


variable "enable_dlm_snapshots" {
  description = "Enable EBS volume snapshots"
  type        = bool
  default     = false
}

variable "ebs_cross_region_settings" {
  type = list(object({
    region        = string
    cmk_arn       = string
    interval      = number
    interval_unit = string
  }))
  default = []
}

variable "snapshot_retention_days" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 7
}

variable "snapshot_frequency_hours" {
  description = "Frequency of snapshots in hours"
  type        = number
  default     = 2
}

variable "coredns_rewrite_rules" {
  type = list(object({
    query  = string
    target = string
  }))
  default = [
    { query = "orderer0.luther.systems", target = "fabric-orderer0.fabric-orderer.svc.cluster.local" },
    { query = "orderer1.luther.systems", target = "fabric-orderer1.fabric-orderer.svc.cluster.local" },
    { query = "orderer2.luther.systems", target = "fabric-orderer2.fabric-orderer.svc.cluster.local" },
    { query = "peer0.org1.luther.systems", target = "fabric-peer0-org1.fabric-org1.svc.cluster.local" },
    { query = "peer1.org1.luther.systems", target = "fabric-peer1-org1.fabric-org1.svc.cluster.local" },
    { query = "peer2.org1.luther.systems", target = "fabric-peer2-org1.fabric-org1.svc.cluster.local" },
    { query = "peer0.org2.luther.systems", target = "fabric-peer0-org2.fabric-org2.svc.cluster.local" },
    { query = "peer1.org2.luther.systems", target = "fabric-peer1-org2.fabric-org2.svc.cluster.local" },
    { query = "peer2.org2.luther.systems", target = "fabric-peer2-org2.fabric-org2.svc.cluster.local" },
    { query = "ca.org1.luther.systems", target = "fabric-ca.fabric-org1.svc.cluster.local" },
    { query = "ca.org2.luther.systems", target = "fabric-ca.fabric-org2.svc.cluster.local" }
  ]
}
