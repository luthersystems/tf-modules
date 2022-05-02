variable "luther_project" {
  type = string
}

variable "aws_region" {
  type    = string
  default = ""
}

variable "az_location" {
  type    = string
  default = ""
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

variable "subcomponent" {
  type    = string
  default = ""
}

variable "resource" {
  type = string
}

variable "id" {
  type        = string
  default     = ""
  description = "DO NOT PROVIDE id IF ALSO PROVIDING replication"
}

variable "replication" {
  type        = number
  default     = 1
  description = "DO NOT PROVIDE replication IF ALSO PROVIDING id"
}

variable "delim" {
  type    = string
  default = "-"
}
