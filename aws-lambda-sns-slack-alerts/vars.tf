variable "aws_region" {
  type = string
}

variable "luther_project" {
  type = string
}

variable "luther_env" {
  type = string
}

variable "org_name" {
  type = string
}

variable "web_hook_url_secret_arn" {
  type = string
}

variable "web_hook_url_secret_region" {
  type    = string
  default = ""
}

variable "secret_kms_key_id" {
  type = string
}

variable "slack_channel" {
  type    = string
  default = "alerts"
}

variable "sns_topic_arn" {
  type = string
}
