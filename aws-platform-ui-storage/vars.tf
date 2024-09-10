data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}

variable "luther_project" {
  type        = string
  description = "A short (three character) identifier for the project"
}

variable "luther_env" {
  type = string
}

variable "external_access_principals" {
  type    = list(string)
  default = []
}

variable "autoscaling_service_role_name" {
  type    = string
  default = "AWSServiceRoleForAutoScaling"
}

variable "has_github" {
  type    = bool
  default = false
}

variable "has_env_admin" {
  type    = bool
  default = false
}

variable "has_vault" {
  type    = bool
  default = false
}

variable "ci_github_org" {
  type    = string
  default = ""
}

variable "ci_github_repo" {
  type    = string
  default = ""
}

variable "ci_github_env" {
  type    = string
  default = ""
}

variable "ci_ecr_push_arns" {
  type    = list(string)
  default = []
}
