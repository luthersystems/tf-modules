output "bucket" {
  value = "${aws_s3_bucket.bucket.bucket}"
}

# NOTE:  This doesn't use hacky template defined inside the module which
# bypasses terraform dependency checking.  If someone needs to use that they
# can reach inside the module and reference it themselves (I think).
output "arn" {
  value = "${aws_s3_bucket.bucket.arn}"
}
