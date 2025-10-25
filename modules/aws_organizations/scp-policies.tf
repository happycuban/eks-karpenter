# Service Control Policies (SCPs) for AWS Organizations
# SCPs define the maximum permissions for accounts in an OU

# Enable SCPs in the organization (if not already enabled)
# Note: This is managed at the organization level

# Base deny policy - Prevent accounts from leaving their OU
resource "aws_organizations_policy" "deny_ou_changes" {
  name        = "DenyOUChanges"
  description = "Prevent accounts from leaving or modifying organizational structure"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyLeaveOrganization"
        Effect = "Deny"
        Action = [
          "organizations:LeaveOrganization",
          "organizations:MoveAccount",
          "organizations:RemoveAccountFromOrganization"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyOrganizationChanges"
        Effect = "Deny"
        Action = [
          "organizations:DeleteOrganizationalUnit",
          "organizations:DeleteOrganization",
          "organizations:CreateOrganizationalUnit",
          "organizations:UpdateOrganizationalUnit"
        ]
        Resource = "*"
      }
    ]
  })
}

# Development OU - Allow broader access for testing
resource "aws_organizations_policy" "dev_restrictions" {
  name        = "DevEnvironmentRestrictions"
  description = "Restrictions for development environment"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAllExceptRestricted"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid    = "DenyProductionAccess"
        Effect = "Deny"
        Action = [
          "organizations:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyExpensiveServices"
        Effect = "Deny"
        Action = [
          "redshift:*",
          "elasticloadbalancing:CreateLoadBalancer",
          "rds:CreateDBInstance",
          "rds:CreateDBCluster"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["eu-central-1", "eu-west-1"]
          }
        }
      }
    ]
  })
}

# Test OU - Similar to dev but with some testing constraints
resource "aws_organizations_policy" "test_restrictions" {
  name        = "TestEnvironmentRestrictions"
  description = "Restrictions for test environment"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAllExceptRestricted"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid    = "DenyProductionAccess"
        Effect = "Deny"
        Action = [
          "organizations:*"
        ]
        Resource = "*"
      },
      {
        Sid      = "RestrictRegions"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["eu-central-1", "eu-west-1"]
          }
          StringNotEquals = {
            "aws:PrincipalOrgID" = [data.aws_organizations_organization.root.id]
          }
        }
      }
    ]
  })
}

# Staging OU - More restrictive, closer to production standards
resource "aws_organizations_policy" "staging_restrictions" {
  name        = "StagingEnvironmentRestrictions"
  description = "Restrictions for staging environment"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAllExceptRestricted"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid    = "DenyDangerousActions"
        Effect = "Deny"
        Action = [
          "organizations:*",
          "account:CloseAccount",
          "iam:DeleteAccountPasswordPolicy",
          "iam:UpdateAccountPasswordPolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "RequireMFAForCriticalActions"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "rds:DeleteDBInstance",
          "s3:DeleteBucket"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      },
      {
        Sid      = "RestrictToSpecificRegion"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["eu-central-1"]
          }
        }
      }
    ]
  })
}

# Production OU - Most restrictive policies
resource "aws_organizations_policy" "production_restrictions" {
  name        = "ProductionEnvironmentRestrictions"
  description = "Strict restrictions for production environment"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAllExceptRestricted"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid    = "DenyDangerousActions"
        Effect = "Deny"
        Action = [
          "organizations:*",
          "account:CloseAccount",
          "iam:DeleteAccountPasswordPolicy",
          "iam:UpdateAccountPasswordPolicy",
          "iam:CreateAccountAlias",
          "iam:DeleteAccountAlias"
        ]
        Resource = "*"
      },
      {
        Sid    = "RequireMFAForCriticalActions"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          "s3:DeleteBucket",
          "s3:DeleteObject",
          "dynamodb:DeleteTable",
          "lambda:DeleteFunction"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      },
      {
        Sid      = "RestrictToProductionRegion"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["eu-central-1"]
          }
        }
      },
      {
        Sid      = "DenyRootAccountUsage"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })
}

# Attach base policy to all OUs
resource "aws_organizations_policy_attachment" "dev_base" {
  policy_id = aws_organizations_policy.deny_ou_changes.id
  target_id = aws_organizations_organizational_unit.exampleorg-dev.id
}

resource "aws_organizations_policy_attachment" "test_base" {
  policy_id = aws_organizations_policy.deny_ou_changes.id
  target_id = aws_organizations_organizational_unit.exampleorg-tes.id
}

resource "aws_organizations_policy_attachment" "staging_base" {
  policy_id = aws_organizations_policy.deny_ou_changes.id
  target_id = aws_organizations_organizational_unit.exampleorg-sta.id
}

resource "aws_organizations_policy_attachment" "production_base" {
  policy_id = aws_organizations_policy.deny_ou_changes.id
  target_id = aws_organizations_organizational_unit.exampleorg-pro.id
}

# Attach environment-specific policies to each OU
resource "aws_organizations_policy_attachment" "dev_restrictions" {
  policy_id = aws_organizations_policy.dev_restrictions.id
  target_id = aws_organizations_organizational_unit.exampleorg-dev.id
}

resource "aws_organizations_policy_attachment" "test_restrictions" {
  policy_id = aws_organizations_policy.test_restrictions.id
  target_id = aws_organizations_organizational_unit.exampleorg-tes.id
}

resource "aws_organizations_policy_attachment" "staging_restrictions" {
  policy_id = aws_organizations_policy.staging_restrictions.id
  target_id = aws_organizations_organizational_unit.exampleorg-sta.id
}

resource "aws_organizations_policy_attachment" "production_restrictions" {
  policy_id = aws_organizations_policy.production_restrictions.id
  target_id = aws_organizations_organizational_unit.exampleorg-pro.id
}
