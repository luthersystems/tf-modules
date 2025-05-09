variable "luther_project" {
  type        = string
  description = "A short (three character) identifier for the project"
}

variable "luther_env" {
  type = string
}

variable "component" {
  type    = string
  default = "logs"
}

variable "random_identifier" {
  type        = string
  description = "A randomly generated string to mitigate namespace sniffing globally defined S3 bucket names"
  default     = ""
}

variable "aws_kms_key_arn" {
  type        = string
  description = "The KMS key to encrypt the bucket"
  default     = ""
}

variable "dr_bucket_replication" {
  type        = bool
  default     = false
  description = "Whether to replicate to disaster recovery bucket"
}

variable "replication_role_arn" {
  type        = string
  default     = ""
  description = "Role arn for S3 bucket replication"
}

variable "replication_destination_arn" {
  type        = string
  default     = ""
  description = "Destination arn for S3 bucket replication"
}

variable "destination_kms_key_arn" {
  type        = string
  default     = ""
  description = "Destination kms key arn for S3 bucket replication"
}

variable "lifecycle_rules" {
  type = list(map(string))

  default = []
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "replicate_deletes" {
  type    = bool
  default = true
}
