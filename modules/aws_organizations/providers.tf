###############################################################################
# Required Providers (no provider configuration in modules)
###############################################################################
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

###############################################################################
# Data Sources (module logic, not provider configuration)
###############################################################################
data "aws_organizations_organization" "root" {}

locals {
  root_id = data.aws_organizations_organization.root.roots[0].id
}