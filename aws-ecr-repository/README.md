# AWS ECR Repository

Creates a repository and the associated access policy.

```
module "example" {
  source = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//aws-ecr-repository"
  name   = "luthersystems/example"

  ro_principals = ["${join(
    var.account_principals,
    var.readonly_user_principals,
  )}"]

  rw_principals = ["${var.readwrite_user_principals}"]
}
```
