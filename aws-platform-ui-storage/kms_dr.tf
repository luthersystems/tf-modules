module "luthername_kms_key_main_dr" {
  source         = "../luthername"
  luther_project = var.luther_project
  aws_region     = var.aws_region_dr
  luther_env     = var.luther_env
  org_name       = "luther"
  component      = "storage"
  resource       = "kms"
  id             = random_string.kms_key_main.result
}

resource "aws_kms_key" "main_dr" {
  provider = aws.dr_region

  description = "Master DR KMS key for storage encryption"
  policy      = data.aws_iam_policy_document.kms_key_main.json
  tags        = module.luthername_kms_key_main_dr.tags
}

resource "aws_kms_alias" "main_dr" {
  provider = aws.dr_region

  name          = "alias/${module.luthername_kms_key_main_dr.name}"
  target_key_id = aws_kms_key.main_dr.key_id
}

locals {
  kms_key_dr_arn    = aws_kms_key.dr.arn
  kms_key_alias_arn = aws_kms_alias.main_dr.arn
}

output "kms_key_main_arn_dr" {
  value = local.kms_key_dr_arn
}

output "kms_alias_main_arn_dr" {
  value = local.kms_key_alias_arn
}
