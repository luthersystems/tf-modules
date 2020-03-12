output "user_pool_id" {
  value = "${aws_cognito_user_pool.org.id}"
}

output "user_pool_arn" {
  value = "${aws_cognito_user_pool.org.arn}"
}

output "user_pool_base_url" {
  value = "${data.template_file.user_pool_base_url.rendered}"
}

output "user_pool_webkey_url" {
  value = "${data.template_file.user_pool_webkey_url.rendered}"
}

output "user_pool_domain" {
  value = "${aws_cognito_user_pool_domain.org.domain}"
}
