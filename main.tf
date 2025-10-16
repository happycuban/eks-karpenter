###############################################################################
# VPC
###############################################################################
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = var.env
    Env  = var.env
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "${var.env}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  intra_subnets   = ["10.0.104.0/24", "10.0.105.0/24", "10.0.106.0/24"]

  enable_dns_hostnames   = true
  enable_dns_support     = true
  single_nat_gateway     = true
  enable_nat_gateway     = true
  reuse_nat_ips          = true
  one_nat_gateway_per_az = false
  external_nat_ip_ids    = [aws_eip.nat.id]

  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = {
    Env = var.env
  }
}

###############################################################################
# EKS
###############################################################################
resource "aws_iam_role" "eks_role" {
  name = "${var.env}-${var.cluster_name}-eks-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "eks.amazonaws.com"
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name    = var.cluster_name
  cluster_version = "1.33"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  iam_role_arn = aws_iam_role.eks_role.arn

  eks_managed_node_groups = {
    karpenter = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "BOTTLEROCKET_x86_64" # BOTTLEROCKET_x86_64: Best for Kubernetes-focused, security-conscious, immutable infrastructure. AL2023_x86_64_STANDARD: Best for general workloads that need package management, scripting, and flexibility.
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 5
      desired_size = 2

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }

      taints = {
        # This Taint aims to keep just EKS Addons and Karpenter running on this MNG
        # The pods that do not tolerate this taint should run on nodes created by Karpenter
        addons = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        },
      }
    }
  }

  # Cluster access entry
  # Disable automatic cluster creator to prevent GitHub Actions from becoming the creator
  # We explicitly manage access entries below to ensure consistent permissions
  enable_cluster_creator_admin_permissions = false

  # Grant access to both GitHub Actions and maintain personal cluster creator access
  access_entries = {
    # Ensure personal account always has cluster admin access regardless of who runs Terraform
    cluster_creator = {
      principal_arn = "arn:aws:iam::203889108834:user/tf-playground"
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # Grant GitHub Actions OIDC role deployment access
    github-actions = {
      principal_arn = "arn:aws:iam::203889108834:role/github-actions"
      type          = "STANDARD"
      policy_associations = {
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            namespaces = ["default", "kube-system", "argocd", "cert-manager"]
            type       = "namespace"
          }
        }
        cluster_view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  node_security_group_tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.cluster_name
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}


###############################################################################
# Automatically Attach ECR Read-Only Policy to All EKS Node Groups
###############################################################################
resource "aws_iam_role_policy_attachment" "eks_nodes_ecr_readonly" {
  for_each = module.eks.eks_managed_node_groups # Loops over all node groups

  role       = each.value.iam_role_name # Gets IAM role for each node group
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

  depends_on = [module.eks] # Ensures EKS is created first
}

###############################################################################
# Karpenter
###############################################################################
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.37.2"

  cluster_name                    = module.eks.cluster_name
  create_pod_identity_association = true

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

###############################################################################
# Karpenter Helm
###############################################################################
resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.8.0"
  wait                = false

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    dnsPolicy: Default
    serviceAccount:
      name: ${module.karpenter.service_account}
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
      featureGates:
        staticCapacity: false
    EOT
  ]

  # Idempotent behavior: If release exists, this will upgrade it
  # If it doesn't exist, this will install it
  atomic          = true
  cleanup_on_fail = true
}

###############################################################################
# Karpenter Kubectl
###############################################################################
resource "kubectl_manifest" "karpenter_node_pool" {
  provider  = kubectl.alekc
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["4", "8", "16", "32"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
          taints: []
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        budgets:
        - nodes: "20%"
          reasons:
          - "Empty"
          - "Drifted"
        consolidateAfter: 30s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  provider  = kubectl.alekc
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiSelectorTerms:
        - alias: bottlerocket@latest
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
