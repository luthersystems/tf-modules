module "luthername_cogpool" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region
  luther_env     = var.luther_env
  org_name       = var.org_name
  component      = var.component
  resource       = "cogpool"
}

# NOTE:  In version 1.13.0 of the terraform aws provider there seem to be bugs
# involving updates to cognito resources.  If you are trying to modify cognito
# resources verify behavior in a staging environment before attempting to
# modify a production environment.  Look for newer releases of the aws provider
# which address cognito bugs.
#
#       https://github.com/terraform-providers/terraform-provider-aws/blob/master/CHANGELOG.md

resource "aws_cognito_user_pool" "org" {
  name = module.luthername_cogpool.names[0]

  #mfa_configuration = "OPTIONAL"

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
  admin_create_user_config {
    allow_admin_create_user_only = true

    invite_message_template {
      # NOTE:  The terraform docs say that sms_message is optional but it
      # is lying.  A template must be supplied, apparently.
      sms_message = "Your ${var.org_human} ${var.luther_project_human} username is {username} and your password is {####}"

      email_subject = "${var.org_human} ${var.luther_project_human} temporary password"

      email_message = <<EOT
<div>
    <p>
    Welcome, ${var.org_human} user, to the ${var.luther_project_human} project.
    </p>

    <p>
    Log into the ${var.luther_project_human} portal with the following username and temporary
    password.
    </p>
</div>

<div>
    <p>
    username: <strong>{username}</strong>
    </p>

    <p>
    password: <strong>{####}</strong>
    </p>
</div>

<div>
    <p>
    Ater logging in you will be prompted to create a secure password that you will
    use going forward.
    </p>

    <p>
    Without logging into the portal within the next 7 days your account will be
    automatically deleted and administrators will need to create a new account for
    you, if you wish.
    </p>
</div>
EOT

    }
  }

  # NOTE:  You can't change the schema at all with version 1.13.0 of the aws
  # provider.  It will cause downtime if the schema changes.  The autoscaling
  # group needs to be torn down, recreated, reprovisioned.  Try not to do it.
  #
  # NOTE:  If the constraints on the 'standard' OpenIDConnect attributes
  # (e.g. name and email) do not match the constraints given by amazon
  # terraform will never be able to satisfy the configuration and will always
  # try to recreate a more-perfect user pool.  The only reason to include the
  # attributes in the schema **at all** is to make them required.
  schema {
    attribute_data_type = "String"
    name                = "email"
    mutable             = true
    required            = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
  schema {
    attribute_data_type = "String"
    name                = "name"
    mutable             = true
    required            = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
  schema {
    attribute_data_type = "String"
    name                = "org"
    mutable             = true
    required            = false

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
  tags = {
    Name         = module.luthername_cogpool.names[0]
    Project      = module.luthername_cogpool.luther_project
    Environment  = module.luthername_cogpool.luther_env
    Organization = module.luthername_cogpool.org_name
    Component    = module.luthername_cogpool.component
    Resource     = module.luthername_cogpool.resource
    ID           = module.luthername_cogpool.ids[0]
  }
}

resource "aws_cognito_user_group" "admin" {
  name         = "luther:admin"
  user_pool_id = aws_cognito_user_pool.org.id
  description  = "Luther Systems administrators"
}

resource "aws_cognito_user_pool_domain" "org" {
  domain       = "luthersystems-${var.luther_project}-${var.luther_env}-${var.org_name}-0"
  user_pool_id = aws_cognito_user_pool.org.id
}
