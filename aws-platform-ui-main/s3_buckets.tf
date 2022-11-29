data "aws_s3_bucket" "env_static" {
  bucket = var.env_static_s3_bucket
}
