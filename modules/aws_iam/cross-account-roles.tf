# Cross-Account IAM Roles
# These roles will be created in each member account to allow access from the management account

# Note: These roles need to be created in each member account
# You can use Terraform providers with assume_role or AWS CloudFormation StackSets

# Trust policy for roles in member accounts
locals {
  # Get management account ID
  management_account_id = data.aws_organizations_organization.root.master_account_id

  # Trust policy allowing management account users to assume roles
  cross_account_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.management_account_id}:root"
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
}

# Example: Full Admin Role for Dev/Test/Staging accounts
data "aws_iam_policy_document" "admin_role_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.management_account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["exampleorg-cross-account"]
    }
  }
}

# Example: Read-Only Role for Production account
data "aws_iam_policy_document" "readonly_role_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.management_account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["exampleorg-cross-account"]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

# Output the trust policies for manual creation in member accounts
output "cross_account_trust_policy" {
  description = "Trust policy for cross-account roles"
  value       = local.cross_account_trust_policy
}

output "management_account_id" {
  description = "Management account ID"
  value       = local.management_account_id
}
