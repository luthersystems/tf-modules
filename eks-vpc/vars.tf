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
  type = string
}

variable "worker_instance_type" {
  type    = string
  default = "m5.large"
}

variable "domain" {
  type = string
}

variable "bastion_ssh_port" {
  default = 2222
}

variable "bastion_ami" {
  type = string
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
  type = string
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
  type = string
}

# To access all keys in the bucket pass the list ["*"]
variable "storage_s3_key_prefixes" {
  type = list(string)
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
