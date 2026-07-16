variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "org_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "admin_principals" {
  type = list(string)
}

variable "admin_role_name" {
  type    = string
  default = "admin"
}

variable "create_state_bucket" {
  type    = bool
  default = true
}

variable "create_dns" {
  type    = bool
  default = true
}

variable "kms_alias_suffix" {
  type    = string
  default = "tfstate"
}

# Optional least-privilege inputs for the admin (deploy) role — see
# luthersystems/sandbox-infrastructure-template#147 and its design doc
# (docs/design/least-privilege-deploy-role.md). Both default to "" so every
# existing consumer keeps EXACTLY the current behavior (AdministratorAccess
# attached, no permissions boundary) until it opts in.

variable "deploy_policy_json" {
  description = "Optional JSON policy body for a customer-managed deploy policy. When non-empty, the module creates the policy and attaches it to the admin role IN PLACE OF the AWS-managed AdministratorAccess policy. When empty (default), AdministratorAccess is attached, unchanged."
  type        = string
  default     = ""
}

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions-boundary policy ARN to set on the admin role (defense-in-depth cap). When empty (default), no boundary is set, unchanged."
  type        = string
  default     = ""
}
