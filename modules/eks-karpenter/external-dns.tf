###############################################################################
# EXTERNAL DNS - Pod Identity Configuration
###############################################################################

# IAM Policy for ExternalDNS to manage Route53 records
resource "aws_iam_policy" "external_dns" {
  name        = "${var.env}-external-dns-policy"
  description = "IAM policy for ExternalDNS to manage Route53 DNS records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })

  tags = {
    Environment = var.env
    Service     = "external-dns"
  }
}

# IAM Role for ExternalDNS using Pod Identity
resource "aws_iam_role" "external_dns" {
  name = "${var.env}-external-dns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Environment = var.env
    Service     = "external-dns"
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external_dns.name
}

# EKS Pod Identity Association
resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external_dns.arn

  tags = {
    Environment = var.env
    Service     = "external-dns"
  }

  depends_on = [module.eks]
}

# ExternalDNS Helm Release
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.15.0"

  # Idempotent behavior: If release exists, this will upgrade it
  # If it doesn't exist, this will install it
  atomic          = true
  cleanup_on_fail = true

  set = [
    {
      name  = "serviceAccount.name"
      value = "external-dns"
    },
    {
      name  = "provider.name"
      value = "aws"
    },
    {
      name  = "aws.region"
      value = var.region
    },
    {
      name  = "domainFilters[0]"
      value = var.domain_name
    },
    {
      name  = "policy"
      value = "upsert-only"
    },
    {
      name  = "aws.zoneType"
      value = "public"
    },
    {
      name  = "registry"
      value = "txt"
    },
    {
      name  = "txtOwnerId"
      value = var.cluster_name
    },
    {
      name  = "logFormat"
      value = "text"
    },
    {
      name  = "logLevel"
      value = "info"
    },
    {
      name  = "sources[0]"
      value = "service"
    },
    {
      name  = "sources[1]"
      value = "ingress"
    },
    {
      name  = "resources.limits.memory"
      value = "256Mi"
    },
    {
      name  = "resources.limits.cpu"
      value = "200m"
    },
    {
      name  = "resources.requests.memory"
      value = "128Mi"
    },
    {
      name  = "resources.requests.cpu"
      value = "100m"
    },
    {
      name  = "tolerations[0].key"
      value = "CriticalAddonsOnly"
    },
    {
      name  = "tolerations[0].operator"
      value = "Exists"
    },
    {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
    }
  ]

  depends_on = [
    module.eks,
    aws_eks_pod_identity_association.external_dns
  ]
}