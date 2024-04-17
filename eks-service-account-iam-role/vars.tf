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
