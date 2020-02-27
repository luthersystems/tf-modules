module "luthername" {
  source = "git::ssh://git@bitbucket.org/luthersystems/tf-modules.git//luthername?ref=master"
  luther_project = "terraform-test"
  aws_region = "eu-west-2"
  luther_env = "dev"
  org_name = "luther"
  component = "infra"
  resource = "tf"
}
