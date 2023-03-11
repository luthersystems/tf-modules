locals {
  user_pool_webkey_url = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.org.id}/.well-known/jwks.json"
  user_pool_base_url   = "https://${aws_cognito_user_pool_domain.org.domain}.auth.${var.aws_region}.amazoncognito.com"
}
