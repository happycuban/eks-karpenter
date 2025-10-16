locals {
  github_subs = flatten([
    for item in var.github_repos : [
      "repo:${item}:ref:refs/heads/*",
      "repo:${item}:environment:production"
    ]
  ])
  ecr_repos = [for item in var.github_repos : "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${lower(item)}"]
}

module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.1"

  name = "github-actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "eks:*",
          "iam:*",
          "kms:*",
          "logs:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          "route53:*",
          "ecr:*",
          "ecr-public:*",
          "sts:*",
          "sqs:*",
          "events:*",
          "s3:*",
          "dynamodb:*"
        ]
        Resource = "*"
      }
    ]
  })
}

module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.1"

  name = "github-actions"

  use_name_prefix = false

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals = [{
        type        = "Federated"
        identifiers = [module.iam_oidc_provider.arn]
      }]
      condition = [{
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:aud"
        values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values   = local.github_subs
        }
      ]
    }
  }

  policies = {
    ECRReadWrite = module.iam_policy.arn
  }
}