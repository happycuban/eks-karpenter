# IAM Policies for cross-account access to different OUs

# Policy: Full access to Development OU accounts
resource "aws_iam_policy" "dev_full_access" {
  name        = "DevelopmentOUFullAccess"
  description = "Full access to Development OU accounts via AssumeRole"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeRoleInDevelopmentAccounts"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::${local.dev_account_id}:role/exampleorg",
          "arn:aws:iam::${local.dev_account_id}:role/*-admin",
          "arn:aws:iam::${local.dev_account_id}:role/*-full-access"
        ]
      },
      {
        Sid    = "ListAccountsAndOUs"
        Effect = "Allow"
        Action = [
          "organizations:ListAccounts",
          "organizations:ListAccountsForParent",
          "organizations:DescribeAccount",
          "organizations:DescribeOrganizationalUnit"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name         = "DevOpsFullAccessDev"
    ManagedBy    = local.manage
    Organization = local.organization
    Environment  = "development"
  }
}

# Policy: Full access to Dev, Test, Staging OUs and Read-only to Production
resource "aws_iam_policy" "devops_multi_env_access" {
  name        = "DevOpsMultiEnvironmentAccess"
  description = "Full access to Dev/Test/Staging, Read-only to Production"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeFullAccessRoles"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          # Development
          "arn:aws:iam::${local.dev_account_id}:role/exampleorg",
          "arn:aws:iam::${local.dev_account_id}:role/*-admin",
          "arn:aws:iam::${local.dev_account_id}:role/*-full-access",
          # Test
          "arn:aws:iam::${local.tes_account_id}:role/exampleorg",
          "arn:aws:iam::${local.tes_account_id}:role/*-admin",
          "arn:aws:iam::${local.tes_account_id}:role/*-full-access",
          # Staging
          "arn:aws:iam::${local.sta_account_id}:role/exampleorg",
          "arn:aws:iam::${local.sta_account_id}:role/*-admin",
          "arn:aws:iam::${local.sta_account_id}:role/*-full-access"
        ]
      },
      {
        Sid    = "AssumeReadOnlyRolesProduction"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::${local.pro_account_id}:role/exampleorg",
          "arn:aws:iam::${local.pro_account_id}:role/*-read-only",
          "arn:aws:iam::${local.pro_account_id}:role/*-viewer"
        ]
      },
      {
        Sid    = "ListAccountsAndOUs"
        Effect = "Allow"
        Action = [
          "organizations:ListAccounts",
          "organizations:ListAccountsForParent",
          "organizations:DescribeAccount",
          "organizations:DescribeOrganizationalUnit",
          "organizations:ListOrganizationalUnitsForParent"
        ]
        Resource = "*"
      },
      {
        Sid    = "ManageOwnCredentials"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ChangePassword",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:GetAccessKeyLastUsed",
          "iam:ListAccessKeys",
          "iam:UpdateAccessKey",
          "iam:ListMFADevices",
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      }
    ]
  })

  tags = {
    Name         = "DevOpsMultiEnvAccess"
    ManagedBy    = local.manage
    Organization = local.organization
    Environment  = "multi"
  }
}

# Policy for allowing users to list and see role information
resource "aws_iam_policy" "base_console_access" {
  name        = "BaseConsoleAccess"
  description = "Base permissions for AWS Console access"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ViewConsoleInformation"
        Effect = "Allow"
        Action = [
          "iam:GetAccountSummary",
          "iam:ListAccountAliases",
          "sts:GetCallerIdentity",
          "organizations:DescribeOrganization"
        ]
        Resource = "*"
      },
      {
        Sid    = "ViewOwnUserInfo"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:GetUserPolicy",
          "iam:ListGroupsForUser",
          "iam:ListAttachedUserPolicies",
          "iam:ListUserPolicies"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      }
    ]
  })

  tags = {
    Name         = "BaseConsoleAccess"
    ManagedBy    = local.manage
    Organization = local.organization
  }
}
