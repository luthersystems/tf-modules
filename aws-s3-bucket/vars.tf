variable "luther_project" {
  type        = "string"
  description = "A short (three character) identifier for the project"
}

variable "luther_env" {
  type = "string"
}

variable "org_name" {
  type    = "string"
  default = ""
}

variable "org_human" {
  type    = "string"
  default = "luther"
}

variable "component" {
  type    = "string"
  default = "logs"
}

variable "random_identifier" {
  type        = "string"
  description = "A randomly generated string to mitigate namespace sniffing globally defined S3 bucket names"
}

variable "aws_kms_key_arn" {
  type        = "string"
  description = "The KMS key to encrypt the bucket"

  # This default is the Luther Systems default KMS key for S3 buckets defined
  # in the common-infrastructure repository.
  default = "arn:aws:kms:eu-west-2:967058059066:key/4cf1dd96-7fd0-4d76-8cc6-4d991d6b27cf"
}