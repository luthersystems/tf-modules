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
