variable "luther_project" {
  type = "string"
}

variable "luther_env" {
  type = "string"
}

variable "org_name" {
  type    = "string"
  default = ""
}

variable "component" {
  type = "string"
}

variable "replication" {
  type    = "string"
  default = "1"
}

variable "should_exist" {
  type = "string"
}

variable "aws_ebs_volume_ids" {
  type = "list"
}
