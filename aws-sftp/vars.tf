variable "luther_env" {
  type = "string"
}

variable "org_name" {
  type = "string"
}

variable "luther_project" {
  type = "string"
}

variable "bucket_kms_key_arn" {
  type = "string"
}

variable "cloudwatch_log_group" {
  type = "string"
}

variable "secrets_prefix" {
  type = "string"
}

variable "bucket_prefix_patterns" {
  default = ["*"]
}

variable "sftp_whitelist_ingress" {
  type        = "list"
  description = "List of allowed CIDRs."
}
