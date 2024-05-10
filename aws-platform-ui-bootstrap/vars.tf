variable "project" {
}

variable "env" {
}

variable "org_name" {
}

variable "admin_principals" {
  type = list(string)
}

variable "admin_role_name" {
  default = "admin"
}

variable "create_state_bucket" {
  default = true
}

variable "kms_alias_suffix" {
  default = "tfstate"
}
