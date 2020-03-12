variable "luther_project" {
  type        = "string"
  description = "short form project identifier (e.g., 'ded', 'dpl', etc)"
}

variable "luther_project_name" {
  type        = "string"
  description = "short form project name (e.g., 'dedupe', 'partnerloan', etc)"
}

variable "luther_project_human" {
  type        = "string"
  description = "long form project name (e.g., 'Fraud Detection', 'DLA Partner Loan', etc)"
}

variable "org_name" {
  type        = "string"
  description = "short form name of organization (e.g., 'dla')"
}

variable "org_human" {
  type        = "string"
  description = "long form organization name (e.g., 'DLA Piper')"
}

variable "luther_env" {
  type        = "string"
  description = "environment name (e.g., 'demo', 'dev', 'prod')"
}

variable "component" {
  type        = "string"
  description = "Component tag"
}
