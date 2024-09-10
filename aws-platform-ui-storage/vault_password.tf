module "luthername_vault_password_secret" {
  source         = "github.com/luthersystems/tf-modules//luthername?ref=v54.0.0"
  luther_project = var.luther_project
  aws_region     = local.region
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "vaultpass"
  resource       = "sm"
  id             = random_string.vault_password_id.result
}

resource "random_string" "vault_password_id" {
  length  = 4
  upper   = false
  special = false
}

resource "random_password" "vault_password" {
  length           = 32      # AES-256 requires a 32-byte key
  special          = true    # Include special characters
  upper            = true    # Include uppercase characters
  lower            = true    # Include lowercase characters
  numeric          = true    # Include numeric characters
  min_special      = 4       # Ensure there are at least 4 special characters
  override_special = "_%@!-" # Restrict special characters to make it compatible with Ansible Vault
}

resource "aws_secretsmanager_secret" "vault_password" {
  count = var.has_vault ? 0 : 1

  name        = module.luthername_vault_password_secret.name
  description = "This is a secret used for ansible vault password"

  tags = module.luthername_vault_password_secret.tags
}

resource "aws_secretsmanager_secret_version" "vault_password" {
  count = var.has_vault ? 0 : 1

  secret_id      = aws_secretsmanager_secret.vault_password[0].id
  secret_string  = random_password.vault_password.result
  version_stages = ["AWSCURRENT"]
}

output "vault_password_secret_name" {
  value = try(aws_secretsmanager_secret.vault_password[0].name, null)
}

output "vault_password_secret_arn" {
  value = try(aws_secretsmanager_secret.vault_password[0].arn, null)
}

data "aws_iam_policy_document" "get_vault_password_secret" {
  statement {
    sid = "AllowGetSecretValue"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]


    resources = [
      try(aws_secretsmanager_secret.vault_password[0].arn, null),
    ]
  }
}

resource "aws_iam_policy" "env_admin_vault_password_secret_policy" {
  count = var.has_vault && var.has_env_admin ? 0 : 1

  name   = "${module.luthername_vault_password_secret.name}-admin"
  policy = data.aws_iam_policy_document.get_vault_password_secret.json

  tags = module.luthername_vault_password_secret.tags
}

resource "aws_iam_role_policy_attachment" "env_admin_vault_password_secret_policy_attachment" {
  count = var.has_vault && var.has_env_admin ? 0 : 1

  role       = aws_iam_role.env_admin_role[0].name
  policy_arn = aws_iam_policy.env_admin_vault_password_secret_policy[0].arn
}
