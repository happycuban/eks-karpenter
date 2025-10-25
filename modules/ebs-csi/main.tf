###############################################################################
# EBS CSI - Pod Identity Configuration
###############################################################################
# IAM Role for EBS CSI Driver using Pod Identity
resource "aws_iam_role" "ebs_csi_pod_identity" {
  name = "${var.cluster_name}-ebs-csi-pod-identity"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEksAuthToAssumeRoleForPodIdentity"
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
    Terraform   = "true"
    Purpose     = "EBS-CSI-Pod-Identity"
    Cluster     = var.cluster_name
    Service     = "kubernetes-ebs-csi-driver"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Attach EBS CSI policy to the role
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_pod_identity.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Custom policy for KMS access
resource "aws_iam_role_policy" "ebs_csi_kms_policy" {
  name = "${var.cluster_name}-ebs-csi-kms"
  role = aws_iam_role.ebs_csi_pod_identity.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = var.ebs_csi_kms
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = var.ebs_csi_kms
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = "1.33"
  most_recent        = true
}

# EKS Pod Identity Association for EBS CSI
resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_pod_identity.arn

  tags = {
    Environment = var.env
    Terraform   = "true"
    Purpose     = "EBS-CSI-Pod-Identity"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  addon_version               = data.aws_eks_addon_version.ebs_csi.version
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_pod_identity_association.ebs_csi
  ]

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

###############################################################################
# Storage Class
###############################################################################
resource "kubectl_manifest" "ebs_csi_default_storage_class" {
  count = var.create_default_storage_class ? 1 : 0

  yaml_body = <<-YAML
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    annotations:
      storageclass.kubernetes.io/is-default-class: "true"
    name: ${var.storage_class_name}
    labels:
      app.kubernetes.io/managed-by: "terraform"
      environment: ${var.env}
  provisioner: ebs.csi.aws.com
  reclaimPolicy: Delete
  volumeBindingMode: WaitForFirstConsumer
  allowVolumeExpansion: true
  parameters:
    type: ${var.storage_type}
    fsType: ext4
    encrypted: "true"
    ${var.ebs_csi_kms != null ? "kmsKeyId: \"${var.ebs_csi_kms}\"" : ""}
  YAML

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}