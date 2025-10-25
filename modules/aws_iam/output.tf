output "devops" {
  description = "print the credentials devops"
  value = {
    login              = aws_iam_user.devopsuser.name
    encrypted_password = aws_iam_user_login_profile.devopsuser.encrypted_password
  }
}

output "devuser" {
  description = "print the credentials dev"
  value = {
    login              = aws_iam_user.devuser.name
    encrypted_password = aws_iam_user_login_profile.devuser.encrypted_password
    arn                = aws_iam_user.devuser.arn
    group              = aws_iam_group.developer.name
    access_scope       = "Full access to Development OU accounts"
  }
}

# Policy ARNs
output "policies" {
  description = "Created IAM policies"
  value = {
    dev_full_access = {
      arn  = aws_iam_policy.dev_full_access.arn
      name = aws_iam_policy.dev_full_access.name
    }
    devops_multi_env = {
      arn  = aws_iam_policy.devops_multi_env_access.arn
      name = aws_iam_policy.devops_multi_env_access.name
    }
    base_console = {
      arn  = aws_iam_policy.base_console_access.arn
      name = aws_iam_policy.base_console_access.name
    }
  }
}

# Account IDs for cross-account access
output "target_accounts" {
  description = "Target account IDs for cross-account access"
  value = {
    development = local.dev_account_id
    test        = local.tes_account_id
    staging     = local.sta_account_id
    production  = local.pro_account_id
  }
}

# Instructions for users
output "user_access_instructions" {
  description = "How users should access different environments"
  value = {
    devuser = {
      user        = aws_iam_user.devuser.name
      access      = "Full access to Development OU"
      assume_role = "arn:aws:iam::${local.dev_account_id}:role/exampleorg"
      console_url = "https://console.aws.amazon.com/"
    }
    devopsuser = {
      user   = aws_iam_user.devopsuser.name
      access = "Full: Dev/Test/Staging, Read-only: Production"
      assume_roles = {
        development = "arn:aws:iam::${local.dev_account_id}:role/exampleorg"
        test        = "arn:aws:iam::${local.tes_account_id}:role/exampleorg"
        staging     = "arn:aws:iam::${local.sta_account_id}:role/exampleorg"
        production  = "arn:aws:iam::${local.pro_account_id}:role/exampleorg"
      }
      console_url = "https://console.aws.amazon.com/"
    }
  }
}