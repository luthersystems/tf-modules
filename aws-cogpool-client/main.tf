module "luthername_cogpool_client" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/terraform-aws-luthername.git?ref=v1.0.0"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "${var.component}"
  resource       = "cogclient"

  providers = {
    template = "template"
  }
}

# BUG:  Updates to user pool clients don't work well with terraform aws
# provider version 1.13.  If you want to change something about the user pool
# client you probably have to taint to client and recreate it for the settings
# to be applied correctly.  If you don't want to do that (because you will have
# to destroy the autoscaling group) then you'd better make sure it works in the
# staging environment before doing it in production!
resource "aws_cognito_user_pool_client" "app" {
  name                                 = "${module.luthername_cogpool_client.names[count.index]}"
  user_pool_id                         = "${var.user_pool_id}"
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "aws.cognito.signin.user.admin", "profile"]
  callback_urls                        = ["${var.callback_urls}"]
  default_redirect_uri                 = "${var.default_redirect_uri}"
  supported_identity_providers         = ["COGNITO"]

  # this secret will end up in the terraform state file.
  generate_secret = true
}
