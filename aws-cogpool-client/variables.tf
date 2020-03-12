variable "luther_project" {
  type        = string
  description = "short form project name (e.g., 'ded', 'dpl', etc)"
}

variable "luther_env" {
  type        = string
  description = "environment name (e.g., 'demo', 'dev', 'prod')"
}

variable "component" {
  type        = string
  description = "Component tag"
  default     = "app"
}

variable "org_name" {
  type        = string
  description = "short form name of organization (e.g., 'dla')"
}

variable "user_pool_id" {
  type        = string
  description = "ID of the user pool"
}

variable "user_pool_base_url" {
  type        = string
  description = "The base url (derived from an aws_cognito_user_pool_domain)"
}

variable "callback_urls" {
  type        = list(string)
  description = "valid OAuth callback URLs"
}

variable "default_redirect_uri" {
  type        = string
  description = "default OAuth callback redirect"
}
