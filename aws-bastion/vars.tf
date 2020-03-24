variable "luther_project" {
  type = string
}

variable "luther_env" {
  type = string
}

variable "org_name" {
  type    = string
  default = ""
}

variable "component" {
  type = string

  # a default component is defined in this module because it will typically
  # be "bastion"
  default = "bastion"
}

variable "aws_instance_type" {
  type = string
}

variable "aws_ami" {
  type = string
}

variable "root_volume_size_gb" {
  type    = string
  default = "8"
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_subnet_ids" {
  type = list(string)
}

variable "ssh_port" {
  type    = string
  default = "2222"
}

variable "ssh_whitelist_ingress" {
  type    = list(string)
  default = []
}

variable "prometheus_server_security_group_id" {
  type = string
}

variable "prometheus_node_exporter_metrics_port" {
  type    = string
  default = "9111"
}

variable "authorized_key_sync_metrics_port" {
  type    = string
  default = "9112"
}

variable "authorized_key_sync_s3_bucket_arn" {
  type = string
}

variable "authorized_key_sync_s3_key_prefix" {
  type    = string
  default = "/"
}

variable "aws_kms_key_arns" {
  type        = list(string)
  description = "KMS used to encrypt objects in the buckets accessed by the ASG"
}

#variable "project_static_asset_s3_bucket_arn" {
#   type = "string"
#}

variable "common_static_asset_s3_bucket_arn" {
  type = string
}

variable "aws_cloudwatch_alarm_actions_enabled" {
  type    = string
  default = "true"
}

variable "aws_autorecovery_sns_arn" {
  type = string
}

variable "aws_autorestart_arn" {
  type = string
}

variable "cloudwatch_log_group" {
  type = string
}

variable "cloudwatch_log_group_arn" {
  type = string
}
