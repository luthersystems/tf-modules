variable "name" {
  type = string
}

# ro_principals lists AWS principals that have readonly access to the
# repository (docker pull)
#
# ECR repository policies may only have principals which are roles, account
# account roots, or users.
variable "ro_principals" {
  type = list(string)
}

# rw_principals lists AWS principals that have readwrite access to the
# repository (docker push & docker pull)
#
# ECR repository policies may only have principals which are roles, account
# account roots, or users.
variable "rw_principals" {
  type = list(string)
}

# scan_on_push scans each image for known CVEs when it is pushed. Set it to
# false only where a registry-level scanning configuration (which overrides
# it) is in use.
variable "scan_on_push" {
  type    = bool
  default = true
}
