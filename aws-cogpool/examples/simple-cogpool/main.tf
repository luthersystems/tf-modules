provider "aws" {
  region = "eu-west-2"
}

module "idp" {
  source               = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//aws-cogpool?ref=master"
  aws_region           = "eu-west-2"
  luther_project       = "tst"
  luther_project_name  = "testp"
  luther_project_human = "Simple Example"
  luther_env           = "test"
  component            = "testc"
  org_name             = "testo"
  org_human            = "Test Organization"

  providers = {
    aws = "aws"
  }
}

output "user_pool_id" {
  value = "${module.idp.user_pool_id}"
}

output "user_pool_base_url" {
  value = "${module.idp.user_pool_base_url}"
}

output "user_pool_webkey_url" {
  value = "${module.idp.user_pool_base_url}"
}

output "user_pool_domain" {
  value = "${module.idp.user_pool_domain}"
}
