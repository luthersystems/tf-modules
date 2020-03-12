variable "aws_region" {
  type = "string"
}

variable "replication" {
  type        = "string"
  description = "must equal the number of instance ids supplied.  required due to terraform module restrictions"
}

variable "instance_names" {
  type = "list"
}

variable "aws_instance_ids" {
  type = "list"
}

variable "aws_cloudwatch_alarm_actions_enabled" {
  type    = "string"
  default = "true"
}

variable "aws_autorestart_arn" {
  type = "string"
}

variable "aws_autorecovery_sns_arn" {
  type = "string"
}
