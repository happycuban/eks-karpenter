# AWS IAM Users and Cross-Account Access

Terraform configuration for managing IAM users with cross-account access to different AWS Organizations OUs.

## 🎯 Overview

This module creates IAM users in the **management account** with policies that allow them to assume roles in member accounts across different OUs.

### Users and Access Levels

| User | Group | Development | Test | Staging | Production |
|------|-------|------------|------|---------|------------|
| `devuser` | Developer | ✅ Full Access | ❌ No Access | ❌ No Access | ❌ No Access |
| `devopsuser` | DevOps_Engineer | ✅ Full Access | ✅ Full Access | ✅ Full Access | 👁️ Read-Only |

## 🏗️ Architecture

### How It Works

1. **IAM Users** are created in the **management account**
2. Users are assigned to **Groups** with specific policies
3. **Policies** grant permission to **assume roles** in member accounts
4. **Roles** exist in each **member account** (dev, test, staging, production)
5. Users **assume roles** to access resources in member accounts

```
Management Account                Member Accounts
┌─────────────────┐              ┌──────────────────────┐
│                 │              │  Development         │
│  devuser        │─────────────▶│  role: exampleorg   │
│  (Developer)    │  AssumeRole  │  permissions: Admin  │
│                 │              └──────────────────────┘
└─────────────────┘

┌─────────────────┐              ┌──────────────────────┐
│                 │              │  Development         │
│  devopsuser     │─────────────▶│  role: exampleorg   │
│  (DevOps)       │  AssumeRole  │  permissions: Admin  │
│                 │              ├──────────────────────┤
│                 │              │  Test                │
│                 │─────────────▶│  role: exampleorg   │
│                 │  AssumeRole  │  permissions: Admin  │
│                 │              ├──────────────────────┤
│                 │              │  Staging             │
│                 │─────────────▶│  role: exampleorg   │
│                 │  AssumeRole  │  permissions: Admin  │
│                 │              ├──────────────────────┤
│                 │              │  Production          │
│                 │─────────────▶│  role: exampleorg   │
│                 │  AssumeRole  │  permissions: Read   │
└─────────────────┘              └──────────────────────┘
```

## 📋 Files

### `aws-iam.tf`
User and group definitions:
- **devuser** - Developer user with Development access
- **devopsuser** - DevOps user with multi-environment access
- **Developer** group - For developers
- **DevOps_Engineer** group - For DevOps engineers

### `iam-policies.tf`
Custom IAM policies:
- **DevelopmentOUFullAccess** - Allow assuming roles in Development accounts
- **DevOpsMultiEnvironmentAccess** - Allow assuming roles in Dev/Test/Staging (full), Production (read-only)
- **BaseConsoleAccess** - Basic console access for all users

### `data-sources.tf`
Data sources and locals:
- **terraform_remote_state** - References aws_organizations state file
- **aws_organizations_organization** - Organization data source
- **Locals** - Extracted account IDs and OU IDs from organizations outputs

Automatically retrieves:
- Development, Test, Staging, Production account IDs
- All OU IDs
- Organization root ID

### `cross-account-roles.tf`
Cross-account role trust policies and documentation

### `output.tf`
Outputs for user credentials and access information

### `data-sources.tf`
References to AWS Organizations terraform state for automatic account/OU ID retrieval

## 🚀 Setup

### Prerequisites

**Important**: The `aws_organizations` module must be applied first!

```bash
# Apply organizations first
cd /home/sysadmin/repos/eks-karpenter/aws_organizations
terraform init
terraform apply
```

The IAM module uses Terraform remote state to automatically retrieve:
- Account IDs for all environments
- OU IDs for all organizational units
- Organization root ID

### Step 1: Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply
terraform apply
```

### Step 3: Get User Credentials

```bash
# Get user information
terraform output devuser
terraform output devopsuser

# Get all access instructions
terraform output user_access_instructions
```

## 🔑 User Access Setup

### For devuser (Developer)

1. **Console Login**:
   - URL: https://YOUR-ACCOUNT-ID.signin.aws.amazon.com/console
   - Username: `devuser`
   - Password: (from terraform output)

2. **Access Development Account**:
   - In AWS Console, click your username (top right)
   - Select "Switch Role"
   - Account ID: `<dev-account-id>` (from terraform output)
   - Role: `exampleorg`
   - Display Name: `Development`
   - Color: Blue

3. **CLI Access**:
   ```bash
   # Configure AWS CLI
   aws configure --profile devuser
   
   # Assume role in development account
   aws sts assume-role \
     --role-arn arn:aws:iam::<dev-account-id>:role/exampleorg \
     --role-session-name devuser-session \
     --profile devuser
   ```

### For devopsuser (DevOps Engineer)

1. **Console Login**:
   - URL: https://YOUR-ACCOUNT-ID.signin.aws.amazon.com/console
   - Username: `devopsuser`
   - Password: (from terraform output)

2. **Switch Roles** (create for each environment):

   **Development**:
   - Account: `<dev-account-id>`
   - Role: `exampleorg`
   - Display Name: `Development`
   - Color: Blue

   **Test**:
   - Account: `<test-account-id>`
   - Role: `exampleorg`
   - Display Name: `Test`
   - Color: Yellow

   **Staging**:
   - Account: `<staging-account-id>`
   - Role: `exampleorg`
   - Display Name: `Staging`
   - Color: Orange

   **Production** (Read-Only):
   - Account: `<production-account-id>`
   - Role: `exampleorg`
   - Display Name: `Production-ReadOnly`
   - Color: Red

3. **CLI Access**:
   ```bash
   # Configure AWS CLI
   aws configure --profile devopsuser
   
   # Assume role in development
   aws sts assume-role \
     --role-arn arn:aws:iam::<dev-account-id>:role/exampleorg \
     --role-session-name devops-dev \
     --profile devopsuser
   
   # Assume role in production (read-only)
   aws sts assume-role \
     --role-arn arn:aws:iam::<pro-account-id>:role/exampleorg \
     --role-session-name devops-prod-readonly \
     --profile devopsuser
   ```

## 🔒 Security Considerations

### 1. MFA Enforcement
For production access, consider requiring MFA:

```bash
# Enable MFA for production role assumption (already configured in SCPs)
# Users must enable MFA on their IAM account first
```

### 2. Session Duration
Default session duration is 1 hour. Adjust in member account roles if needed:

```hcl
resource "aws_iam_role" "exampleorg" {
  max_session_duration = 3600  # 1 hour (default)
  # or
  max_session_duration = 43200  # 12 hours (maximum)
}
```

### 3. External ID
Uses `exampleorg-cross-account` as External ID for added security.

### 4. Least Privilege
- devuser: Only Development access
- devopsuser: Read-only in Production (enforced by policy)

## 🛠️ Member Account Configuration

### The `exampleorg` Role

Each member account needs a role that users can assume. This role should already exist (created during account setup in aws_organizations), but here's the structure:

#### In Development/Test/Staging Accounts (Full Access)

```hcl
resource "aws_iam_role" "exampleorg" {
  name = "exampleorg"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::<MANAGEMENT-ACCOUNT-ID>:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "exampleorg-cross-account"
          }
        }
      }
    ]
  })
  
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}
```

#### In Production Account (Read-Only for devopsuser)

You may want separate roles or conditional logic:

```hcl
# Option 1: Separate read-only role
resource "aws_iam_role" "exampleorg_readonly" {
  name = "exampleorg-read-only"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::<MANAGEMENT-ACCOUNT-ID>:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "exampleorg-cross-account"
          }
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })
  
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]
}

# Option 2: Conditional permissions in single role
# Use IAM conditions to limit devopsuser to read-only
```

## 📊 Monitoring and Auditing

### View Role Assumptions

```bash
# CloudTrail events for role assumptions
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --max-results 50

# Check who assumed a role
aws sts get-caller-identity
```

### List User's Current Permissions

```bash
# Simulate policy to see effective permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT-ID:user/devuser \
  --action-names sts:AssumeRole

# List user's groups
aws iam list-groups-for-user --user-name devuser

# List user's attached policies
aws iam list-attached-user-policies --user-name devuser
```

## 🔄 Adding New Users

To add a new user:

1. **Add user resource** in `aws-iam.tf`:
   ```hcl
   resource "aws_iam_user" "newuser" {
     name = "newuser"
     tags = {
       Name         = "New User"
       ManagedBy    = local.manage
       organization = local.organization
     }
   }
   
   resource "aws_iam_user_login_profile" "newuser" {
     user = aws_iam_user.newuser.name
   }
   ```

2. **Add to appropriate group**:
   ```hcl
   resource "aws_iam_group_membership" "developer-group" {
     name  = "Developer"
     users = [
       aws_iam_user.devuser.name,
       aws_iam_user.newuser.name  # Add here
     ]
     group = aws_iam_group.developer.name
   }
   ```

3. **Apply changes**:
   ```bash
   terraform apply
   ```

## 🆘 Troubleshooting

### "User is not authorized to perform: sts:AssumeRole"

**Cause**: User doesn't have permission or role doesn't trust the user.

**Solutions**:
1. Check user's group membership: `aws iam list-groups-for-user --user-name devuser`
2. Check group policies: `aws iam list-attached-group-policies --group-name Developer`
3. Verify role trust policy in member account
4. Verify External ID matches

### "Access Denied" when accessing resources after assuming role

**Cause**: Role doesn't have necessary permissions or SCP is blocking.

**Solutions**:
1. Check role permissions in member account
2. Check SCPs attached to the OU: `aws organizations list-policies-for-target --target-id <ou-id>`
3. Review CloudTrail for denied actions

### Can't find role to switch to in console

**Cause**: Role doesn't exist or user hasn't configured it.

**Solutions**:
1. Verify role exists: `aws iam get-role --role-name exampleorg --profile <account-profile>`
2. Add role to console: AWS Console → Username → Switch Role → Fill in details

## 📚 References

- [AWS IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [AssumeRole API](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
- [Cross-Account Access](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_common-scenarios_aws-accounts.html)
- [Switching Roles (Console)](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-console.html)

---

**Last Updated**: October 10, 2025  
**Maintained By**: ExampleOrg DevOps Team
