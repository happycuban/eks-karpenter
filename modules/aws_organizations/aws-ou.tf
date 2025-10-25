locals {
  dev-ou-name     = "Development"
  tes-ou-name     = "Test"
  sta-ou-name     = "Stage"
  pro-ou-name     = "Production"
  manage          = "Terraform"
  environment-dev = "development"
  environment-tes = "test"
  environment-sta = "stage"
  environment-pro = "production"
  env-dev         = "dev"
  env-tes         = "tes"
  env-sta         = "sta"
  env-pro         = "pro"
  organization    = "exampleorg"
}

resource "aws_organizations_organizational_unit" "exampleorg-dev" {
  name      = "ExampleOrg-Development"
  parent_id = local.root_id
}

resource "aws_organizations_account" "exampleorg-dev" {
  name                       = "development"
  email                      = "aws-development@happycuban-example.dk"
  iam_user_access_to_billing = "ALLOW"
  role_name                  = "exampleorg"
  parent_id                  = aws_organizations_organizational_unit.exampleorg-dev.id
  close_on_deletion          = "true"

  tags = {
    Name         = local.dev-ou-name
    ManagedBy    = local.manage
    Environment  = local.environment-dev
    env          = local.env-dev
    organization = local.organization
  }
}

resource "aws_organizations_organizational_unit" "exampleorg-tes" {
  name      = "ExampleOrg-Test"
  parent_id = local.root_id
}

resource "aws_organizations_account" "exampleorg-tes" {
  name                       = "test"
  email                      = "aws-test@happycuban-example.dk"
  iam_user_access_to_billing = "ALLOW"
  role_name                  = "exampleorg"
  parent_id                  = aws_organizations_organizational_unit.exampleorg-tes.id
  close_on_deletion          = "true"

  tags = {
    Name         = local.tes-ou-name
    ManagedBy    = local.manage
    Environment  = local.environment-tes
    env          = local.env-tes
    organization = local.organization
  }
}

resource "aws_organizations_organizational_unit" "exampleorg-sta" {
  name      = "ExampleOrg-Staging"
  parent_id = local.root_id
}

resource "aws_organizations_account" "exampleorg-sta" {
  name                       = "stage"
  email                      = "aws-stage@happycuban-example.dk"
  iam_user_access_to_billing = "ALLOW"
  role_name                  = "exampleorg"
  parent_id                  = aws_organizations_organizational_unit.exampleorg-sta.id
  close_on_deletion          = "true"

  tags = {
    Name         = local.sta-ou-name
    ManagedBy    = local.manage
    Environment  = local.environment-sta
    env          = local.env-sta
    organization = local.organization
  }
}

resource "aws_organizations_organizational_unit" "exampleorg-pro" {
  name      = "ExampleOrg-Production"
  parent_id = local.root_id
}

resource "aws_organizations_account" "exampleorg-pro" {
  name                       = "production"
  email                      = "aws-production@happycuban-example.dk"
  iam_user_access_to_billing = "ALLOW"
  role_name                  = "exampleorg"
  parent_id                  = aws_organizations_organizational_unit.exampleorg-pro.id
  close_on_deletion          = "true"

  tags = {
    Name         = local.pro-ou-name
    ManagedBy    = local.manage
    Environment  = local.environment-pro
    env          = local.env-pro
    organization = local.organization
  }
}