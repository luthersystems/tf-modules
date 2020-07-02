variable "aws_region" {
  default = "eu-west-2"
}

variable "luther_project" {
  type        = string
  description = "A short (three character) identifier for the project"
}

variable "luther_env" {
  type = string
}

variable "replica_region" {
  default = "eu-west-1"
}

variable "replica_kms_arn" {
  default = ""
}

variable "source_kms_arn" {
  default = ""
}
