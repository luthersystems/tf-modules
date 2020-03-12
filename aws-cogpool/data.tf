data "template_file" "user_pool_webkey_url" {
  template = "https://cognito-idp.$${region}.amazonaws.com/$${user_pool_id}/.well-known/jwks.json"

  vars = {
    region       = var.aws_region
    user_pool_id = aws_cognito_user_pool.org.id
  }
}

data "template_file" "user_pool_base_url" {
  template = "https://$${sub_domain}.auth.$${region}.amazoncognito.com"

  vars = {
    sub_domain = aws_cognito_user_pool_domain.org.domain
    region     = var.aws_region
  }
}
