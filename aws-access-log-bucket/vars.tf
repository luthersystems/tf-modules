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

variable "lifecycle_expiration_id" {
  type    = string
  default = "expiration"
}
