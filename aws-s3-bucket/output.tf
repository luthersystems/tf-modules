# bucket and arn wait for the public access block, so a caller's bucket
# policy on this bucket is applied after it: S3 refuses concurrent changes
# to one bucket's access settings (409 OperationAborted).
output "bucket" {
  value      = aws_s3_bucket.bucket.bucket
  depends_on = [aws_s3_bucket_public_access_block.bucket]
}

output "arn" {
  value      = aws_s3_bucket.bucket.arn
  depends_on = [aws_s3_bucket_public_access_block.bucket]
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.bucket.bucket_regional_domain_name
}
