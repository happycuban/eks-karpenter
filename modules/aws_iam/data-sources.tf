# Data sources to reference AWS Organizations resources
data "aws_organizations_organization" "root" {}

# Reference the terraform state from aws_organizations module
data "terraform_remote_state" "organizations" {
  backend = "local"

  config = {
    path = "${path.module}/../aws_organizations/terraform.tfstate"
  }
}

# Locals to extract values from organizations state
locals {
  # OU IDs from organizations module
  dev_ou_id = data.terraform_remote_state.organizations.outputs.ou_development.id
  tes_ou_id = data.terraform_remote_state.organizations.outputs.ou_test.id
  sta_ou_id = data.terraform_remote_state.organizations.outputs.ou_staging.id
  pro_ou_id = data.terraform_remote_state.organizations.outputs.ou_production.id

  # Account IDs from organizations module
  dev_account_id = data.terraform_remote_state.organizations.outputs.account_development.id
  tes_account_id = data.terraform_remote_state.organizations.outputs.account_test.id
  sta_account_id = data.terraform_remote_state.organizations.outputs.account_staging.id
  pro_account_id = data.terraform_remote_state.organizations.outputs.account_production.id

  # Organization ID
  organization_id = data.aws_organizations_organization.root.id
}
