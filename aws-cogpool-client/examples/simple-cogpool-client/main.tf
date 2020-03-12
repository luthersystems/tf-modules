provider "aws" {
  region = "${var.aws_region}"
}

module "idp" {
  source               = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-cogpool.git?ref=master"
  aws_region           = "${var.aws_region}"
  luther_project       = "${var.luther_project}"
  luther_project_name  = "${var.luther_project_name}"
  luther_project_human = "${var.luther_project_human}"
  luther_env           = "${var.luther_env}"
  org_name             = "${var.org_name}"
  org_human            = "${var.org_human}"
  component            = "testc"

  providers {
    aws = "aws"
  }
}

module "idp-client" {
  source               = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-cogpool-client.git?ref=master"
  aws_region           = "${var.aws_region}"
  luther_project       = "${var.luther_project}"
  luther_env           = "${var.luther_env}"
  org_name             = "${var.org_name}"
  component            = "testc"
  user_pool_id         = "${module.idp.user_pool_id}"
  user_pool_base_url   = "${module.idp.user_pool_base_url}"
  callback_urls        = ["${var.callback_url}"]
  default_redirect_uri = "${var.default_redirect_uri}"

  providers {
    aws = "aws"
  }
}

output "oauth_client_id" {
  value = "${module.idp-client.oauth_client_id}"
}

output "oauth_client_secret" {
  value = "${module.idp-client.oauth_client_secret}"
}

output "oauth_jwt_issuer" {
  value = "${module.idp-client.oauth_jwt_issuer}"
}

output "user_pool_webkey_url" {
  value = "${module.idp-client.user_pool_webkey_url}"
}

output "user_pool_login_url" {
  value = "${module.idp-client.user_pool_login_url}"
}

output "user_pool_token_url" {
  value = "${module.idp-client.user_pool_token_url}"
}
