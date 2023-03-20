output "user_pool_id" {
  value = aws_cognito_user_pool.org.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.org.arn
}

output "user_pool_base_url" {
  value = local.user_pool_base_url
}

output "user_pool_webkey_url" {
  value = local.user_pool_webkey_url
}

output "user_pool_domain" {
  value = aws_cognito_user_pool_domain.org.domain
}
