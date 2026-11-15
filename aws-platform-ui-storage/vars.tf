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

variable "github_oidc_provider_arn" {
  description = "ARN of an existing GitHub Actions OIDC provider (https://token.actions.githubusercontent.com) in the account. Set it for a second deployment in the same account; null creates the provider."
  type        = string
  default     = null

  validation {
    condition     = var.github_oidc_provider_arn == null ? true : can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:oidc-provider/token\\.actions\\.githubusercontent\\.com$", var.github_oidc_provider_arn))
    error_message = "github_oidc_provider_arn must be the ARN of the token.actions.githubusercontent.com OIDC provider."
  }
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

# Opt-in, so a ref bump adds no key to an env that has no EKS cluster or
# does not encrypt its secrets. Turn it on before aws-platform-ui-main's
# eks_secrets_encryption.
variable "eks_secrets_kms_key" {
  type        = bool
  default     = false
  description = "Make a KMS key for EKS secrets encryption (output kms_key_eks_secrets_arn). Once a cluster uses the key, do not turn this off: that schedules the key for deletion, and the cluster's secrets become unreadable when it is deleted."
}
