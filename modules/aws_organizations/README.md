# AWS Organizations

Terraform configuration for managing ExampleOrg's AWS Organization structure, including Organizational Units (OUs) and AWS Accounts.

## 🎯 Overview

This directory contains the Terraform configuration for:
- AWS Organizations root organization
- Organizational Units (OUs) for different environments
- AWS Accounts with proper configuration
- Cross-account IAM roles

## 🏗️ Organization Structure

### Root Organization

The root organization is accessed via data source:
```hcl
data "aws_organizations_organization" "root" {}
```

### Organizational Units (OUs)

The infrastructure creates the following OUs under the root:

- **ExampleOrg-Development** - Development environment
- **ExampleOrg-Test** - Testing environment
- **ExampleOrg-Stage** - Staging environment
- **ExampleOrg-Production** - Production environment

### AWS Accounts

Each OU contains a corresponding AWS account:

| Environment | Account Name | Email | OU | Role Name |
|------------|-------------|-------|-----|-----------|
| Development | development | aws-development@happycuban-example.dk | ExampleOrg-Development | exampleorg |
| Test | test | aws-test@happycuban-example.dk | ExampleOrg-Test | exampleorg |
| Stage | stage | aws-stage@happycuban-example.dk | ExampleOrg-Stage | exampleorg |
| Production | production | aws-production@happycuban-example.dk | ExampleOrg-Production | exampleorg |

### Account Configuration

Each account is configured with:
- **IAM User Access to Billing**: Enabled (`ALLOW`)
- **Cross-Account Role**: `exampleorg` - Allows management from root account
- **Close on Deletion**: Enabled - Accounts will be closed when removed from Terraform

## � Service Control Policies (SCPs)

SCPs are used to limit what actions can be performed in each OU, providing guardrails for each environment.

### Policy Overview

| Policy | Applied To | Purpose |
|--------|-----------|---------|
| `DenyOUChanges` | All OUs | Prevents accounts from leaving organization or modifying structure |
| `DevEnvironmentRestrictions` | Development OU | Allows broad access but denies expensive services in non-EU regions |
| `TestEnvironmentRestrictions` | Test OU | Restricts to specific regions (eu-central-1, eu-west-1) |
| `StagingEnvironmentRestrictions` | Staging OU | Requires MFA for critical actions, restricts to eu-central-1 |
| `ProductionEnvironmentRestrictions` | Production OU | Most restrictive - MFA required, single region, denies root usage |

### Policy Details

#### Base Policy (All Environments)
**DenyOUChanges** - Applied to all OUs
- ❌ Deny leaving organization
- ❌ Deny moving accounts between OUs
- ❌ Deny deleting OUs
- ❌ Deny modifying organization structure

#### Development Environment
**DevEnvironmentRestrictions**
- ✅ Allow most services for development
- ❌ Deny organization management
- ❌ Deny expensive services (Redshift, large RDS) outside EU regions
- 📍 Preferred regions: eu-central-1, eu-west-1

#### Test Environment
**TestEnvironmentRestrictions**
- ✅ Allow services needed for testing
- ❌ Deny organization management
- ❌ Deny services outside allowed regions
- 📍 Restricted to: eu-central-1, eu-west-1

#### Staging Environment
**StagingEnvironmentRestrictions**
- ✅ Allow production-like services
- ❌ Deny dangerous actions (account closure, password policy changes)
- 🔐 Require MFA for: EC2 termination, RDS deletion, S3 bucket deletion
- 📍 Restricted to: eu-central-1 only

#### Production Environment
**ProductionEnvironmentRestrictions** - Most strict
- ✅ Allow only approved production services
- ❌ Deny all organization management
- ❌ Deny account closure and critical IAM changes
- ❌ Deny root account usage entirely
- 🔐 Require MFA for all critical actions:
  - EC2 instance termination
  - RDS database deletion
  - S3 bucket/object deletion
  - DynamoDB table deletion
  - Lambda function deletion
- 📍 Restricted to: eu-central-1 only

### Enabling SCPs

⚠️ **Important**: Service Control Policies must be enabled at the organization level first.

```bash
# Check if SCPs are enabled
aws organizations describe-organization

# Enable all policy types (if needed)
aws organizations enable-policy-type \
  --root-id <root-id> \
  --policy-type SERVICE_CONTROL_POLICY
```

## �📋 Files

### `providers.tf`
Configures the AWS provider with credentials and region settings:
```hcl
provider "aws" {
  shared_credentials_files = var.credentials_file
  profile                  = var.profile
  region                   = var.region
}
```

### `variables.tf`
Defines input variables:
- `credentials_file` - Path to AWS credentials file (default: `["~/.aws/credentials"]`)
- `profile` - AWS CLI profile to use (default: `"default"`)
- `region` - AWS region (default: `"eu-central-1"`)

### `aws-ou.tf`
Contains:
- Local variables defining environment names
- Organizational Unit resources
- AWS Account resources
- Account-OU associations

### `scp-policies.tf`
Service Control Policies for limiting account permissions:
- `DenyOUChanges` - Base policy preventing organizational changes
- `DevEnvironmentRestrictions` - Development environment guardrails
- `TestEnvironmentRestrictions` - Test environment constraints
- `StagingEnvironmentRestrictions` - Staging security requirements
- `ProductionEnvironmentRestrictions` - Production strict controls
- Policy attachments to respective OUs

### `outputs.tf`
Outputs for tracking resources:
- Organization ID and ARN
- OU IDs and ARNs for all environments
- Account IDs and details
- SCP policy IDs and attachments
- Policy attachments summary

## 🚀 Usage

### Initialize

```bash
# Navigate to directory
cd aws_organizations

# Initialize Terraform
terraform init
```

### Plan Changes

```bash
# Preview changes
terraform plan

# Save plan
terraform plan -out=tfplan
```

### Apply Changes

```bash
# Apply with confirmation
terraform apply

# Apply saved plan
terraform apply tfplan
```

### View Resources

```bash
# List all resources
terraform state list

# Show specific OU
terraform state show aws_organizations_organizational_unit.exampleorg-dev

# Show specific account
terraform state show aws_organizations_account.exampleorg-dev

# View SCP policies
terraform state list | grep aws_organizations_policy

# View policy attachments
terraform state list | grep aws_organizations_policy_attachment
```

### Verify SCPs

```bash
# List all policies in the organization
aws organizations list-policies --filter SERVICE_CONTROL_POLICY

# View specific policy content
aws organizations describe-policy --policy-id <policy-id>

# List policies attached to an OU
aws organizations list-policies-for-target --target-id <ou-id> --filter SERVICE_CONTROL_POLICY

# Test if an action is allowed (Policy Simulator)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT-ID:user/USERNAME \
  --action-names ec2:TerminateInstances \
  --resource-arns "*"
```

### View Outputs

```bash
# See all outputs
terraform output

# See specific output
terraform output policy_attachments_summary

# Output in JSON format
terraform output -json account_development
```

## 🔧 Adding New Environments

To add a new environment (e.g., QA):

1. **Add locals in `aws-ou.tf`**:
```hcl
locals {
  # ... existing ...
  qa-ou-name      = "QA"
  qa-account-name = "qa"
}
```

2. **Create OU resource**:
```hcl
resource "aws_organizations_organizational_unit" "exampleorg-qa" {
  name      = "ExampleOrg-${local.qa-ou-name}"
  parent_id = local.root_id
}
```

3. **Create Account resource**:
```hcl
resource "aws_organizations_account" "exampleorg-qa" {
  name                       = local.qa-account-name
  email                      = "aws-qa@happycuban-example.dk"
  iam_user_access_to_billing = "ALLOW"
  parent_id                  = aws_organizations_organizational_unit.exampleorg-qa.id
  role_name                  = "exampleorg"
  close_on_deletion          = true
}
```

4. **Apply changes**:
```bash
terraform plan
terraform apply
```

## 🔐 Security Considerations

### Account Access

- **Root Account**: Should have MFA enabled and used sparingly
- **Cross-Account Role**: Use the `exampleorg` role for accessing accounts from root
- **IAM Policies**: Apply least-privilege policies to all roles

### Account Deletion

⚠️ **WARNING**: Accounts have `close_on_deletion = true`

When you remove an account from Terraform:
1. The account will be **permanently closed**
2. All resources in the account will be deleted
3. Account cannot be reopened (90-day waiting period)

**Before deletion**:
- Backup all important data
- Delete or export resources manually
- Consider using `terraform state rm` to remove from state without deletion

### Email Addresses

- Each account requires a **unique email address**
- Email pattern: `aws-{environment}@happycuban-example.dk`
- Emails cannot be reused for 90 days after account closure

## 🛠️ Troubleshooting

### Common Issues

#### Account Email Already in Use
```bash
# Error: email address already associated with an account
# Solution: Use a different email or wait 90 days after previous account closure
```

#### Insufficient Permissions
```bash
# Error: AccessDenied creating Organizational Unit
# Required permissions:
# - organizations:CreateOrganizationalUnit
# - organizations:CreateAccount
# - organizations:DescribeOrganization
# - iam:CreateRole
```

#### Account Creation Timeout
```bash
# Account creation can take several minutes
# If timeout occurs, check AWS Console or:
aws organizations list-accounts
```

#### Cannot Delete OU
```bash
# Error: OU contains accounts
# Solution: Move or delete accounts first, then delete OU
```

### Import Existing Resources

If resources exist in AWS but not in state:

```bash
# Import OU
terraform import aws_organizations_organizational_unit.exampleorg-dev ou-xxxx-yyyyyyyy

# Import Account
terraform import aws_organizations_account.exampleorg-dev 123456789012
```

## 📚 Resources

### AWS Organizations
- [AWS Organizations Documentation](https://docs.aws.amazon.com/organizations/)
- [Account Management](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts.html)
- [OU Management](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html)

### Terraform Resources
- [aws_organizations_organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization)
- [aws_organizations_organizational_unit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit)
- [aws_organizations_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account)

## 🔄 Best Practices

1. **Always run `terraform plan`** before applying changes
2. **Use workspaces** for managing different organization structures (if needed)
3. **Tag resources** appropriately for cost tracking
4. **Document changes** in commit messages
5. **Test in non-production** environments first
6. **Backup state files** regularly
7. **Review access** to the root account periodically

---

**Maintained By**: ExampleOrg DevOps Team  