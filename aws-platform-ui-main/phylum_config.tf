resource "aws_s3_object" "phylum_config" {
  bucket     = var.env_static_s3_bucket
  key        = "${var.luther_env}/config/config.json.b64"
  kms_key_id = data.aws_kms_key.storage.arn
  content    = base64encode(local.phylum_config)
}

locals {
  phylum_config = <<EOF
{}
EOF

}
