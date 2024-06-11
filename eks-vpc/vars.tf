variable "luther_project" {
  type = string
}

variable "luther_env" {
  type = string
}

variable "org_name" {
  type    = string
  default = "" # in the main project this is all luther org
}

variable "component" {
  type    = string
  default = "main"
}

variable "kubernetes_version" {
  default = "1.23"
}

variable "worker_instance_type" {
  type    = string
  default = "m6i.large"
}

variable "human_domain" {
  default = ""
}

variable "use_bastion" {
  default = false
}

variable "bastion_ssh_port" {
  default = 2222
}

variable "bastion_ami" {
  default = ""
}

variable "bastion_aws_instance_type" {
  type    = string
  default = "t2.small"
}

variable "aws_kms_key_arns" {
  type = list(string)
}

variable "root_volume_size_gb" {
  default = 30
}

variable "volumes_aws_kms_key_id" {
  type = string
}

variable "aws_cloudwatch_log_subscription_filter_lambda_arn" {
  type        = string
  description = "A common lambda function that forwards important log messages to alert devs (e.g. via slack)"
  default     = ""
}

variable "aws_cloudwatch_alarm_actions_enabled" {
  type    = string
  default = "true"
}

variable "aws_cloudwatch_retention_days" {
  type    = number
  default = 90
}

variable "aws_autorecovery_sns_arn" {
  type    = string
  default = ""
}

variable "ssh_public_keys_s3_bucket_arn" {
  default = ""
}

variable "common_static_s3_bucket_arn" {
  type    = string
  default = "arn:aws:s3:::luther-common-ln-common-static-s3-b5oc"
}

variable "common_external_s3_bucket_arn" {
  type    = string
  default = "arn:aws:s3:::luther-common-ln-common-external-s3-44lp"
}

variable "storage_s3_bucket_arn" {
  default = ""
}

# To access all keys in the bucket pass the list ["*"]
variable "storage_s3_key_prefixes" {
  type    = list(string)
  default = []
}

variable "autoscaling_desired" {
  default = 3
}

variable "worker_asg_target_group_arns" {
  type    = list(string)
  default = []
}

variable "inspector_rules_package_arns" {
  type    = list(string)
  default = []
}

variable "public_api" {
  type    = bool
  default = false
}

variable "spot_price" {
  default = ""
}

variable "disable_s3_node_role" {
  default = false
}

variable "disable_alb_node_role" {
  default = true
}

variable "disable_cni_node_role" {
  default = true
}

variable "disable_csi_node_role" {
  default = true
}

variable "kubeproxy_addon" {
  default = true
}

variable "cni_addon" {
  default = true
}

variable "csi_addon" {
  default = true
}

variable "coredns_addon" {
  default = true
}

variable "managed_nodes" {
  default = true
}

# See: https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-24-to-1-25-e1bcccc2f384
# for versions

# https://github.com/aws/amazon-vpc-cni-k8s/releases
variable "cni_addon_version" {
  default = {
    "1.21" = "v1.9.3-eksbuild.1"
    "1.22" = "v1.10.2-eksbuild.1"
    "1.23" = "v1.11.2-eksbuild.1"
    "1.24" = "v1.11.4-eksbuild.1"
    "1.25" = "v1.12.2-eksbuild.1"
    "1.26" = "v1.17.1-eksbuild.1"
    "1.27" = "v1.17.1-eksbuild.1"
    "1.28" = "v1.17.1-eksbuild.1"
    "1.29" = "v1.18.2-eksbuild.1"
  }
}

# https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/CHANGELOG.md
variable "csi_addon_version" {
  default = {
    "1.21" = ""
    "1.22" = "v1.5.2-eksbuild.1"
    "1.23" = "v1.10.0-eksbuild.1"
    "1.24" = "v1.13.0-eksbuild.1"
    "1.25" = "v1.28.0-eksbuild.1"
    "1.26" = "v1.28.0-eksbuild.1"
    "1.27" = "v1.28.0-eksbuild.1"
    "1.28" = "v1.28.0-eksbuild.1"
    "1.29" = "v1.31.0-eksbuild.1"
  }
}

variable "kubeproxy_addon_version" {
  default = {
    "1.21" = "v1.21.2-eksbuild.2"
    "1.22" = "v1.22.6-eksbuild.1"
    "1.23" = "v1.23.7-eksbuild.1"
    "1.24" = "v1.24.7-eksbuild.2"
    "1.25" = "v1.25.6-eksbuild.1"
    "1.26" = "v1.26.13-eksbuild.2"
    "1.27" = "v1.27.1-eksbuild.1"
    "1.28" = "v1.28.1-eksbuild.1"
    "1.29" = "v1.29.0-eksbuild.2"
  }
}

variable "coredns_addon_version" {
  default = {
    "1.21" = "v1.8.4-eksbuild.1"
    "1.22" = "v1.8.7-eksbuild.1"
    "1.23" = "v1.8.7-eksbuild.2"
    "1.24" = "v1.8.7-eksbuild.3"
    "1.25" = "v1.9.3-eksbuild.2"
    "1.26" = "v1.9.3-eksbuild.11"
    "1.27" = "v1.10.1-eksbuild.1"
    "1.28" = "v1.10.1-eksbuild.4"
    "1.29" = "v1.11.1-eksbuild.4"
  }
}

variable "public_worker_ip" {
  default = true
}

#
# Helper to upgrade from 1.21 to 1.23
#
variable "k8s1_21to1_23_upgrade_step" {
  default = 0
}

variable "monitoring" {
  default = false
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

variable "preserve_coredns" {
  default = true
}

variable "slack_alerts_web_hook_url_secret" {
  default = ""
}

variable "alert_rules" {
  default = ""
}

variable "awslogs_driver" {
  default = true
}

variable "data_volume_space_threshold" {
  description = "Threshold for triggering data volume space alerts, represented as a fraction of 1"
  type        = number
  default     = 0.2
}

variable "root_volume_space_threshold" {
  description = "Threshold for triggering root volume space alerts, represented as a fraction of 1"
  type        = number
  default     = 0.2
}

variable "instance_memory_threshold" {
  description = "Threshold for triggering instance memory alerts, represented as a fraction of 1"
  type        = number
  default     = 0.2
}

variable "worker_volume_type" {
  default = "gp2"
}

variable "bastion_replication" {
  default = 1
}

variable "bastion_volume_type" {
  default = "gp3"
}

variable "enable_csi_vol_mod" {
  default = false
}

variable "bastion_ssh_whitelist" {
  default = ["0.0.0.0/0"]
}

variable "fabric_namespace_ro_service_accounts" {
  type        = list(string)
  description = "List of namespaces for read-only service accounts"
  default     = ["fabric-org1", "fabric-org2", "fabric-orderer"]
}

variable "fabric_namespace_snapshot_service_accounts" {
  type        = list(string)
  description = "List of namespaces for snapshot service accounts"
  default     = ["fabric-org1", "fabric-org2"]
}

variable "storage_s3_bucket_snapshot_prefix" {
  default = "fabric-snapshots"
}
