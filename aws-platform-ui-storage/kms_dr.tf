module "luthername_kms_key_main_dr" {
  count = var.enable_dr ? 1 : 0

  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = local.region_dr
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "storage"
  resource       = "kms"
  id             = random_string.kms_key_main.result
}

resource "aws_kms_key" "main_dr" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  description = "Master DR KMS key for storage encryption"
  policy      = data.aws_iam_policy_document.kms_key_main.json
  tags        = module.luthername_kms_key_main_dr[0].tags
}

resource "aws_kms_alias" "main_dr" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  name          = "alias/${module.luthername_kms_key_main_dr[0].name}"
  target_key_id = aws_kms_key.main_dr[0].key_id
}

locals {
  kms_key_dr_arn    = var.enable_dr ? aws_kms_key.main_dr[0].arn : ""
  kms_key_alias_arn = var.enable_dr ? aws_kms_alias.main_dr[0].arn : ""
}

output "kms_key_main_arn_dr" {
  value = local.kms_key_dr_arn
}

output "kms_alias_main_arn_dr" {
  value = local.kms_key_alias_arn
}
