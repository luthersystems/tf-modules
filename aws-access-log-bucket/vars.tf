variable "luther_project" {
  type        = string
  description = "A short (three character) identifier for the project"
}

variable "luther_env" {
  type = string
}

variable "org_name" {
  type    = string
  default = ""
}

variable "org_human" {
  type    = string
  default = "luther"
}

variable "component" {
  type    = string
  default = "logs"
}

variable "random_identifier" {
  type        = string
  description = "A randomly generated string to mitigate namespace sniffing globally defined S3 bucket names"
}

variable "aws_kms_key_arn" {
  type = string

  # This default is the Luther Systems default KMS key for ALB Access Log
  # Buckets defined in the common-infrastructure repository.
  default = "arn:aws:kms:eu-west-2:967058059066:key/3e991639-ebd3-4a1d-8bff-cb2e4555f5cd"
}
