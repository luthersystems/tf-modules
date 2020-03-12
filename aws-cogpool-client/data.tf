# These urls aren't used directly by the aws_user_pool_client but it is used by
# projects which import the module.

data "template_file" "user_pool_issuer_url" {
  template = "https://cognito-idp.$${region}.amazonaws.com/$${user_pool_id}"

  vars {
    region       = "${var.aws_region}"
    user_pool_id = "${var.user_pool_id}"
  }
}

data "template_file" "user_pool_webkey_url" {
  template = "$${issuer_url}/.well-known/jwks.json"

  vars {
    issuer_url = "${data.template_file.user_pool_issuer_url.rendered}"
  }
}

data "template_file" "user_pool_login_url" {
  template = "$${base_url}/login"

  vars {
    base_url = "${var.user_pool_base_url}"
  }
}

data "template_file" "user_pool_token_url" {
  template = "$${base_url}/token"

  vars {
    base_url = "${var.user_pool_base_url}"
  }
}
