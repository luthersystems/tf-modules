output "oauth_client_id" {
  value = "${aws_cognito_user_pool_client.app.id}"
}

output "oauth_client_secret" {
  value = "${aws_cognito_user_pool_client.app.client_secret}"
}

output "oauth_jwt_issuer" {
  value = "${data.template_file.user_pool_issuer_url.rendered}"
}

output "user_pool_webkey_url" {
  value = "${data.template_file.user_pool_webkey_url.rendered}"
}

output "user_pool_login_url" {
  value = "${data.template_file.user_pool_login_url.rendered}"
}

output "user_pool_token_url" {
  value = "${data.template_file.user_pool_token_url.rendered}"
}
