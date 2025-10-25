locals {
  github_subs = flatten([
    for item in var.github_repos : [
      "repo:${item}:ref:refs/heads/*",
      "repo:${item}:environment:production"
    ]
  ])
  ecr_repos = [for item in var.github_repos : "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${lower(item)}"]
}

###############################################################################
# IAM Policy for GitHub Actions
###############################################################################
resource "aws_iam_policy" "github_actions" {
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

###############################################################################
# IAM Role for GitHub Actions
###############################################################################
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subs
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
