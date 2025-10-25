# Outputs for AWS Organizations

# Organization
output "organization_id" {
  description = "The ID of the organization"
  value       = data.aws_organizations_organization.root.id
}

output "organization_arn" {
  description = "The ARN of the organization"
  value       = data.aws_organizations_organization.root.arn
}

output "organization_root_id" {
  description = "The ID of the root organizational unit"
  value       = local.root_id
}

# Organizational Units
output "ou_development" {
  description = "Development OU details"
  value = {
    id   = aws_organizations_organizational_unit.exampleorg-dev.id
    arn  = aws_organizations_organizational_unit.exampleorg-dev.arn
    name = aws_organizations_organizational_unit.exampleorg-dev.name
  }
}

output "ou_test" {
  description = "Test OU details"
  value = {
    id   = aws_organizations_organizational_unit.exampleorg-tes.id
    arn  = aws_organizations_organizational_unit.exampleorg-tes.arn
    name = aws_organizations_organizational_unit.exampleorg-tes.name
  }
}

output "ou_staging" {
  description = "Staging OU details"
  value = {
    id   = aws_organizations_organizational_unit.exampleorg-sta.id
    arn  = aws_organizations_organizational_unit.exampleorg-sta.arn
    name = aws_organizations_organizational_unit.exampleorg-sta.name
  }
}

output "ou_production" {
  description = "Production OU details"
  value = {
    id   = aws_organizations_organizational_unit.exampleorg-pro.id
    arn  = aws_organizations_organizational_unit.exampleorg-pro.arn
    name = aws_organizations_organizational_unit.exampleorg-pro.name
  }
}

# Accounts
output "account_development" {
  description = "Development account details"
  value = {
    id    = aws_organizations_account.exampleorg-dev.id
    arn   = aws_organizations_account.exampleorg-dev.arn
    name  = aws_organizations_account.exampleorg-dev.name
    email = aws_organizations_account.exampleorg-dev.email
  }
}

output "account_test" {
  description = "Test account details"
  value = {
    id    = aws_organizations_account.exampleorg-tes.id
    arn   = aws_organizations_account.exampleorg-tes.arn
    name  = aws_organizations_account.exampleorg-tes.name
    email = aws_organizations_account.exampleorg-tes.email
  }
}

output "account_staging" {
  description = "Staging account details"
  value = {
    id    = aws_organizations_account.exampleorg-sta.id
    arn   = aws_organizations_account.exampleorg-sta.arn
    name  = aws_organizations_account.exampleorg-sta.name
    email = aws_organizations_account.exampleorg-sta.email
  }
}

output "account_production" {
  description = "Production account details"
  value = {
    id    = aws_organizations_account.exampleorg-pro.id
    arn   = aws_organizations_account.exampleorg-pro.arn
    name  = aws_organizations_account.exampleorg-pro.name
    email = aws_organizations_account.exampleorg-pro.email
  }
}

# Service Control Policies
output "scp_deny_ou_changes" {
  description = "Base SCP to prevent OU changes"
  value = {
    id   = aws_organizations_policy.deny_ou_changes.id
    arn  = aws_organizations_policy.deny_ou_changes.arn
    name = aws_organizations_policy.deny_ou_changes.name
  }
}

output "scp_dev_restrictions" {
  description = "SCP for development environment"
  value = {
    id   = aws_organizations_policy.dev_restrictions.id
    arn  = aws_organizations_policy.dev_restrictions.arn
    name = aws_organizations_policy.dev_restrictions.name
  }
}

output "scp_test_restrictions" {
  description = "SCP for test environment"
  value = {
    id   = aws_organizations_policy.test_restrictions.id
    arn  = aws_organizations_policy.test_restrictions.arn
    name = aws_organizations_policy.test_restrictions.name
  }
}

output "scp_staging_restrictions" {
  description = "SCP for staging environment"
  value = {
    id   = aws_organizations_policy.staging_restrictions.id
    arn  = aws_organizations_policy.staging_restrictions.arn
    name = aws_organizations_policy.staging_restrictions.name
  }
}

output "scp_production_restrictions" {
  description = "SCP for production environment"
  value = {
    id   = aws_organizations_policy.production_restrictions.id
    arn  = aws_organizations_policy.production_restrictions.arn
    name = aws_organizations_policy.production_restrictions.name
  }
}

# Policy Attachments Summary
output "policy_attachments_summary" {
  description = "Summary of policy attachments to OUs"
  value = {
    development = {
      ou_id = aws_organizations_organizational_unit.exampleorg-dev.id
      policies = [
        aws_organizations_policy.deny_ou_changes.name,
        aws_organizations_policy.dev_restrictions.name
      ]
    }
    test = {
      ou_id = aws_organizations_organizational_unit.exampleorg-tes.id
      policies = [
        aws_organizations_policy.deny_ou_changes.name,
        aws_organizations_policy.test_restrictions.name
      ]
    }
    staging = {
      ou_id = aws_organizations_organizational_unit.exampleorg-sta.id
      policies = [
        aws_organizations_policy.deny_ou_changes.name,
        aws_organizations_policy.staging_restrictions.name
      ]
    }
    production = {
      ou_id = aws_organizations_organizational_unit.exampleorg-pro.id
      policies = [
        aws_organizations_policy.deny_ou_changes.name,
        aws_organizations_policy.production_restrictions.name
      ]
    }
  }
}
