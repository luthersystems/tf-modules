variable "luther_project" {
  type = string
}

variable "aws_region" {
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
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_name" {
  type = string
}

variable "k8s_namespace" {
  type    = string
  default = ""
}

variable "namespace_service_accounts" {
  type        = map(list(string))
  description = "Map of namespaces to a list of service accounts"
  default     = {}
}

variable "service_account" {
  type = string
}

variable "policy_name" {
  type    = string
  default = "main"
}

variable "policy" {
  type    = string
  default = ""
}

variable "add_policy" {
  type    = bool
  default = false
}

variable "id" {
  default = ""
}

variable "trusted_role_arns" {
  type        = list(string)
  description = "List of AWS IAM Role ARNs that can assume this role"
  default     = []
}

# A pod that calls AssumeRoleWithWebIdentity itself (not through the SDK's
# automatic refresh) gets one session that cannot renew. The Argo terraform
# pods do that: an init container mints a session scoped to one project and
# exits, so the step's container never holds the IRSA token
# (luthersystems/ui-infrastructure#442). Such a session must outlast the
# longest step, which is longer than the AWS default of one hour.
variable "max_session_duration" {
  description = "Maximum session length, in seconds, of the role (3600 to 43200)."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be from 3600 to 43200 seconds."
  }
}
