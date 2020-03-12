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
