###############################################################################
# Data Sources
###############################################################################
data "aws_eks_cluster" "eks" {
  name = var.cluster_name
  depends_on = [
    module.eks
  ]
}

data "aws_eks_cluster_auth" "eks" {
  name = var.cluster_name
  depends_on = [
    module.eks
  ]
}

###############################################################################
# INSTALL TRAEFIK USING HELM
###############################################################################
resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  namespace  = "kube-system"
  version    = "34.4.1"

  values = [file("${path.module}/values/traefik-values.yaml")]

  # Add toleration for CriticalAddonsOnly
  set = [
    {
      name  = "tolerations[0].key"
      value = "CriticalAddonsOnly"
      }, {
      name  = "tolerations[0].operator"
      value = "Exists"
      }, {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
  }]

  depends_on = [
    helm_release.aws_lbc,
    helm_release.external_dns
  ]

  # Idempotent behavior: If release exists, this will upgrade it
  # If it doesn't exist, this will install it
  atomic          = true
  cleanup_on_fail = true
}

resource "kubectl_manifest" "traefik-dashboard" {
  provider  = kubectl.alekc
  yaml_body = file("${path.module}/values/traefik-dashboard.yaml")

  depends_on = [
    helm_release.traefik
  ]
}

data "aws_route53_zone" "selected" {
  zone_id = var.hosted_zone_id
}

resource "helm_release" "cert_manager" {
  name = "cert-manager"

  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.17.1"

  values = [file("${path.module}/values/cert-manager-values.yaml")]

  # Add toleration for CriticalAddonsOnly
  set = [
    {
      name  = "tolerations[0].key"
      value = "CriticalAddonsOnly"
      }, {
      name  = "tolerations[0].operator"
      value = "Exists"
      }, {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
  }]

  # Idempotent behavior: If release exists, this will upgrade it
  # If it doesn't exist, this will install it
  atomic          = true
  cleanup_on_fail = true

  depends_on = [helm_release.traefik]
}

###############################################################################
# AWS ROUTE53 IAM POLICY FOR CERT-MANAGER DNS-01 CHALLENGE
###############################################################################
resource "aws_iam_policy" "cert_manager_route53" {
  name        = "cert-manager-route53"
  description = "IAM policy for Cert Manager to use Route53 for DNS-01 challenges"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets"]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ListHostedZonesByName"
        Resource = "*"
      }
    ]
  })
}

###############################################################################
# CERT-MANAGER POD IDENTITY SETUP (REPLACING HARDCODED KEYS)
###############################################################################

# IAM Role for cert-manager with Pod Identity
resource "aws_iam_role" "cert_manager" {
  name = "${var.env}-cert-manager-role"

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
    Service     = "cert-manager"
  }
}

# Attach the existing Route53 policy to the new role
resource "aws_iam_role_policy_attachment" "cert_manager_route53" {
  policy_arn = aws_iam_policy.cert_manager_route53.arn
  role       = aws_iam_role.cert_manager.name
}

# EKS Pod Identity Association for cert-manager
resource "aws_eks_pod_identity_association" "cert_manager" {
  cluster_name    = module.eks.cluster_name
  namespace       = "cert-manager"
  service_account = "cert-manager"
  role_arn        = aws_iam_role.cert_manager.arn

  tags = {
    Environment = var.env
    Service     = "cert-manager"
  }

  depends_on = [module.eks, helm_release.cert_manager]
}

###############################################################################
# CLUSTER ISSUER FOR LET'S ENCRYPT
###############################################################################
resource "kubectl_manifest" "cert_manager_http_issuer" {
  provider  = kubectl.alekc
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: cert-manager-acme-issuer
      namespace: cert-manager
    spec:
      acme:
        email: "drift@mindworking.dk"
        server: "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef:
          name: cert-manager-acme-private-key
        solvers:
        - http01:
            ingress:
              class: traefik
  YAML

  depends_on = [helm_release.cert_manager]
}

###############################################################################
# CLUSTER ISSUER FOR LET'S ENCRYPT USING DNS ROUTE53
###############################################################################
resource "kubectl_manifest" "cert_manager_dns_issuer" {
  provider   = kubectl.alekc
  yaml_body  = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: cert-manager-acme-route53-issuer
      namespace: cert-manager
    spec:
      acme:
        email: "drift@mindworking.dk"
        server: "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef:
          name: cert-manager-acme-private-key
        solvers:
        - dns01:
            route53:
              region: ${var.region}
  YAML
  depends_on = [
    helm_release.cert_manager,
    aws_eks_pod_identity_association.cert_manager
  ]
}

###############################################################################
# SET TRAEFIK DEFAULT TLS
###############################################################################
resource "kubectl_manifest" "traefik-default-certificate-tls" {
  provider   = kubectl.alekc
  yaml_body  = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: wildcard-happycuban-cert
      namespace: kube-system
    spec:
      commonName: "happycuban-example.dk"  # Replace with your domain
      secretName: wildcard-happycuban-cert
      dnsNames:
        - "happycuban-example.dk"
        - "*.happycuban-example.dk"
      issuerRef:
        name: cert-manager-acme-route53-issuer
        kind: ClusterIssuer

  YAML
  depends_on = [kubectl_manifest.cert_manager_dns_issuer]
}

resource "kubectl_manifest" "traefik-default-tls" {
  provider   = kubectl.alekc
  yaml_body  = <<-YAML
    apiVersion: traefik.io/v1alpha1
    kind: TLSStore
    metadata:
      name: default
      namespace: kube-system

    spec:
      certificates:
        - secretName:  wildcard-happycuban-cert
      defaultCertificate:
        secretName:  wildcard-happycuban-cert

  YAML
  depends_on = [kubectl_manifest.traefik-default-certificate-tls]
}

# Route53 DNS records are now managed by ExternalDNS automatically
# The traefik service has external-dns.alpha.kubernetes.io/hostname annotation
# which will create the *.happycuban-example.dk DNS record pointing to the load balancer
