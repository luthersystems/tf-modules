# SFTP with AWS Transfer

This module implements an SFTP server based on the AWS Transfer service with
support for password auth using secrets stored in AWS Secrets Manager.  This is
based on example code from an AWS blog post:
https://aws.amazon.com/blogs/storage/enable-password-authentication-for-aws-transfer-for-sftp-using-aws-secrets-manager/

The configuration looks something like this:
```
module "luthername_sftp_secrets_prefix" {
  source         = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=master"
  luther_project = "${var.luther_project}"
  aws_region     = "${var.aws_region}"
  luther_env     = "${var.luther_env}"
  org_name       = "${var.org_name}"
  component      = "sftp"
  resource       = "user"

  providers = {
    template = "template"
  }
}

module "sftp" {
  source = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//aws-sftp?ref=vX.X.X"

  aws_region           = "${var.aws_region}"
  aws_account_id       = "${var.aws_account_id}"
  luther_env           = "${var.luther_env}"
  org_name             = "${var.org_name}"
  luther_project       = "${var.luther_project}"
  bucket_kms_key_arn   = "${aws_kms_key.project_key.arn}"
  cloudwatch_log_group = "${aws_cloudwatch_log_group.main.arn}"
  secrets_prefix       = "${module.luthername_sftp_secrets_prefix.names[0]}"

  providers = {
    aws      = "aws"
    template = "template"
    random   = "random"
    archive  = "archive"
  }
}

output "s3_bucket_sftp" {
  value = "${module.sftp.bucket}"
}

output "s3_bucket_arn_sftp" {
  value = "${module.sftp.bucket_arn}"
}

output "transfer_server_endpoint" {
  value = "${module.sftp.transfer_server_endpoint}"
}

locals {
  testuser_name = "${module.luthername_sftp_secrets_prefix.names[0]}/testuser"

  testuser_tags = {
    Name         = "${local.testuser_name}"
    Project      = "${module.luthername_sftp_secrets_prefix.luther_project}"
    Environment  = "${module.luthername_sftp_secrets_prefix.luther_env}"
    Organization = "${module.luthername_sftp_secrets_prefix.org_name}"
    Component    = "${module.luthername_sftp_secrets_prefix.component}"
    Resource     = "${module.luthername_sftp_secrets_prefix.resource}"
    ID           = "${module.luthername_sftp_secrets_prefix.ids[0]}"
  }
}

resource "aws_secretsmanager_secret" "testuser" {
  name                    = "${local.testuser_name}"
  recovery_window_in_days = 0
  tags                    = "${local.testuser_tags}"
}
```

This will create a Transfer Server service with an endpoint (output
`transfer_server_endpoint`) listening on port 22.  A user named `testuser` will
be configured (with additional config below) as a secret in Secrets Manager
named something like `project-region-env-org-sftp-user-0/testuser`.  This module
provides a default role (output `sftp_user_role`) granting read/write on the
bucket using the KMS encryption key.  This can be used when configuring the
user.

## Configuration (password auth)

The user configuration in Secrets Manager (initially undefined) determines the
password, home directory (in an S3 bucket) and the IAM role that grants the user
access to that bucket.  The code below prepares the secret with the intent of
delegating the configuration to Ansible using data (role, bucket, tags,
username) exported as [local
facts](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#local-facts-facts-d).

```
# set up a default value to work around an Ansible bug where secrets cannot be
# managed when no versions exist at all:
# https://github.com/ansible/ansible/blob/v2.8.1/lib/ansible/modules/cloud/amazon/aws_secret.py#L293
resource "aws_secretsmanager_secret_version" "testuser" {
  secret_id     = "${aws_secretsmanager_secret.testuser.id}"
  secret_string = "{}"
}
```

For this use case, the rendered secret should look something like:

```
{
  "Password": "user-password",
  "HomeDirectoryDetails": [
    {
      "Entry": "/visible-directory1",
      "Target": "/sftp-s3-bucket/directory"
    }
  ],
  "Role": "user-role"
}
```

The above config will give the user the specified password and grant the user
access to the `directory` path in the bucket named `sftp-s3-bucket`.  The user
will be dropped into the root of a virtual SFTP server with only that directory
visible (as `visible-directory1`).  Multiple directories from the bucket can be
mapped in.  See [this AWS
doc](https://aws.amazon.com/blogs/storage/using-aws-sftp-logical-directories-to-build-a-simple-data-distribution-service/)
on how this works.

## Public key configuration

Since there is no password, this can be configured directly in terraform:

```
locals {
  testuser_config = {
    HomeDirectoryDetails = [
      {
        Entry  = "/visible-directory"
        Target = "/${module.sftp.bucket}/directory"
      },
    ]

    Role = "${module.sftp.sftp_user_role}"

    PublicKeys = [
      "ssh-ed25519 xxxxx",
      "ssh-rsa xxxxx",
    ]
  }
}

resource "aws_secretsmanager_secret_version" "yardi_user" {
  secret_id     = "${aws_secretsmanager_secret.yardi_user.id}"
  secret_string = "${jsonencode(local.yardi_user_config)}"
}

This will render to something like this:

```
{
  "HomeDirectoryDetails": [
    {
      "Entry": "/visible-directory1",
      "Target": "/sftp-s3-bucket/directory"
    }
  ],
  "Role": "user-role",
  "PublicKeys": [
    "ssh-ed25519 xxxxx",
    "ssh-rsa xxxxxx"
  ]
}
```

## Gotchas

1) It seems you must populate the s3 bucket with a directory and file in order
   for the home directory path to work.

2) It seems you need to "deploy" the staged API (apigw) in order for the lambda
   to be picked up. You may also need to do this when changing the secret value
   in secrets manager.

## Future work
- hashed passwords (requires updating the lambda to hash the incoming user's
  password received from AWS Transfer via API Gateway)
- better management of auto-generated log groups for Transfer, Lambda and API
  Gateway services (expiration).
- possibly disable API GW access logs since it adds no data on top of Lambda and
  Transfer logs
