output "oauth_client_id" {
  value = aws_cognito_user_pool_client.app.id
}

output "oauth_client_secret" {
  value = aws_cognito_user_pool_client.app.client_secret
}

output "oauth_jwt_issuer" {
  value = local.user_pool_issuer_url
}

output "user_pool_webkey_url" {
  value = local.user_pool_webkey_url
}

output "user_pool_login_url" {
  value = local.user_pool_login_url
}

output "user_pool_token_url" {
  value = local.user_pool_token_url
}
