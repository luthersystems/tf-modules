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

variable "domain" {
  default = "luthersystemsapp.com"
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

  default = [
    "arn:aws:kms:eu-west-2:967058059066:key/4cf1dd96-7fd0-4d76-8cc6-4d991d6b27cf",
    "arn:aws:kms:eu-west-2:967058059066:key/078b9b79-8ae6-4d50-9143-1cc3228dd232",
    "arn:aws:kms:eu-central-1:967058059066:key/0ba12ce2-28bd-4761-a578-e0900cace0ca",
    "arn:aws:kms:eu-central-1:967058059066:key/ac3c5328-abcc-471c-8700-80929f067aa7",
  ]
}

variable "volumes_aws_kms_key_id" {
  type    = string
  default = "arn:aws:kms:eu-central-1:967058059066:alias/common-de-common-luther-storage-kms-eoxl"
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

variable "cni_addon_version" {
  default = {
    "1.21" = "v1.9.3-eksbuild.1"
    "1.22" = "v1.10.2-eksbuild.1"
    "1.23" = "v1.11.2-eksbuild.1"
    "1.24" = "v1.11.4-eksbuild.1"
  }
}

variable "csi_addon_version" {
  default = {
    "1.21" = ""
    "1.22" = "v1.5.2-eksbuild.1"
    "1.23" = "v1.10.0-eksbuild.1"
    "1.24" = "v1.13.0-eksbuild.1"
  }
}

variable "kubeproxy_addon_version" {
  default = {
    "1.21" = "v1.21.2-eksbuild.2"
    "1.22" = "v1.22.6-eksbuild.1"
    "1.23" = "v1.23.7-eksbuild.1"
    "1.24" = "v1.24.7-eksbuild.2"
  }
}

variable "coredns_addon_version" {
  default = {
    "1.21" = "v1.8.4-eksbuild.1"
    "1.22" = "v1.8.7-eksbuild.1"
    "1.23" = "v1.8.7-eksbuild.2"
    "1.24" = "v1.8.7-eksbuild.3"
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

variable "use_human_grafana_domain" {
  default = false
}

variable "preserve_coredns" {
  default = false
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
