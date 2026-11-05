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
  default = []
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

# On by default: the key alone changes no cluster, costs one KMS key a
# month, and having it ready lets a cluster turn on secrets encryption
# (aws-platform-ui-main eks_secrets_encryption) with no storage change.
variable "eks_secrets_kms_key" {
  type        = bool
  default     = true
  description = "Make a KMS key for EKS secrets encryption (output kms_key_eks_secrets_arn). Turning it off schedules the key for deletion, which makes the secrets of any cluster that uses it unreadable."
}
