variable "luther_project" {
  type = string
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

variable "replication" {
  type    = number
  default = 1
}

variable "init_volume_size_gb" {
  type    = string
  default = "8"
}

variable "aws_kms_key_arn" {
  type = string
}

variable "aws_availability_zones" {
  type = list(string)

  description = <<EOF
The availability zones in which to create each persistant storage volume.  The
list of availability zones must be passed as a list, instead of being inferred
internally using data sources, to provide backwards compatability if AWS adds a
new AZ to a region.
EOF

}

variable "additional_tags" {
  type    = map(string)
  default = {}
}

variable "additional_per_vol_tags" {
  type    = list(map(string))
  default = []
}

variable "snapshot_ids" {
  default = []
  type    = list(string)
}

variable "init_volume_type" {
  default = "gp3"
}
