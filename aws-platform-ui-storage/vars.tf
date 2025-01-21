data "aws_region" "current" {}

data "aws_region" "dr_region" {
  provider = aws.dr
}

data "aws_caller_identity" "current" {}

locals {
  region     = data.aws_region.current.name
  region_dr  = var.enable_dr ? data.aws_region.dr_region.name : ""
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

variable "ci_github_repos" {
  description = "An array of GitHub org, repo, and environment combinations."
  type = list(object({
    org  = string
    repo = string
    env  = string
  }))
}

variable "ci_ecr_push_arns" {
  type    = list(string)
  default = []
}

variable "ci_static_access" {
  type    = bool
  default = false
}

variable "enable_dr" {
  type    = bool
  default = false
}
