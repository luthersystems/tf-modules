# These urls aren't used directly by the aws_user_pool_client but it is used by
# projects which import the module.

locals {
  user_pool_issuer_url = "https://cognito-idp.${var.aws_region}.amazonaws.com/${var.user_pool_id}"
  user_pool_webkey_url = "${local.user_pool_issuer_url}/.well-known/jwks.json"
  user_pool_login_url  = "${var.user_pool_base_url}/login"
  user_pool_token_url  = "${var.user_pool_base_url}/token"
}
