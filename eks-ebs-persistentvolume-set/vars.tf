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

variable "subcomponent" {
  type    = "string"
  default = ""
}

variable "replication" {
  type    = "string"
  default = "1"
}

variable "volume_size_gb" {
  type    = "string"
  default = "8"
}

variable "aws_kms_key_id" {
  type = "string"
}

variable "aws_availability_zones" {
  type = "list"

  description = <<EOF
The availability zones in which to create each persistant storage volume.  The
list of availability zones must be passed as a list, instead of being inferred
internally using data sources, to provide backwards compatability if AWS adds a
new AZ to a region.
EOF
}

variable "snapshots_should_exist" {
  type = "string"

  description = <<EOF
A boolean value that should be 1 if terraform should create a snapshot during
an apply and 0 otherwise.
EOF
}

variable "fs_type" {
  type    = "string"
  default = "ext4"
}

variable "k8s_labels" {
  type = "map"
}

variable "k8s_storage_class" {
  type    = "string"
  default = "gp2"
}

variable "k8s_access_modes" {
  type = "list"
}
