locals {
  #pgp_key = "keybase:exampleorg"
  manage       = "Terraform"
  organization = "exampleorg"
}

#resource "aws_iam_account_alias" "alias" {
#  account_alias = "exampleorg"
#}

resource "aws_iam_user" "devuser" {
  name = "devuser"
  tags = {
    Name         = "Developer Users"
    ManagedBy    = local.manage
    organization = local.organization
  }
}

resource "aws_iam_user_login_profile" "devuser" {
  user = aws_iam_user.devuser.name
  #pgp_key = local.pgp_key
}

resource "aws_iam_group" "developer" {
  name = "Developer"
  path = "/"
}

resource "aws_iam_group_membership" "dev-group" {
  name  = "Developer"
  users = ["${aws_iam_user.devuser.name}"]
  group = aws_iam_group.developer.name
}

resource "aws_iam_group_policy_attachment" "iam-developer-base" {
  group      = aws_iam_group.developer.name
  policy_arn = aws_iam_policy.base_console_access.arn
}

resource "aws_iam_group_policy_attachment" "iam-developer-change-password" {
  group      = aws_iam_group.developer.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_group_policy_attachment" "iam-developer-dev-access" {
  group      = aws_iam_group.developer.name
  policy_arn = aws_iam_policy.dev_full_access.arn
}

resource "aws_iam_user" "devopsuser" {
  name = "devopsuser"
  tags = {
    Name         = "DevOps"
    ManagedBy    = local.manage
    organization = local.organization
  }
}

resource "aws_iam_user_login_profile" "devopsuser" {
  user = aws_iam_user.devopsuser.name
  #pgp_key = local.pgp_key
}

resource "aws_iam_group" "devops" {
  name = "DevOps_Engineer"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "iam-devops-base" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.base_console_access.arn
}

resource "aws_iam_group_policy_attachment" "iam-devops-change-password" {
  group      = aws_iam_group.devops.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_group_policy_attachment" "iam-devops-multi-env" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.devops_multi_env_access.arn
}

resource "aws_iam_group_membership" "devops-group" {
  name  = "DevOps_Engineer"
  users = ["${aws_iam_user.devopsuser.name}"]
  group = aws_iam_group.devops.name
}