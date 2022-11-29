data "aws_kms_key" "storage" {
  key_id = var.storage_kms_key_arn
}
