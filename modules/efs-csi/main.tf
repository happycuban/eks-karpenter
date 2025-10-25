###############################################################################
# EFS CSI - Pod Identity Configuration
###############################################################################
# IAM Role for EFS CSI Driver using Pod Identity
resource "aws_iam_role" "efs_csi_pod_identity" {
  name = "${var.cluster_name}-efs-csi-pod-identity"

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

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-efs-csi-pod-identity"
    Environment = var.env
    Terraform   = "true"
    Purpose     = "EFS-CSI-Pod-Identity"
    Cluster     = var.cluster_name
    Service     = "kubernetes-efs-csi-driver"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Attach EFS CSI policy to the role
resource "aws_iam_role_policy_attachment" "efs_csi_policy" {
  role       = aws_iam_role.efs_csi_pod_identity.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

# Custom policy for KMS access (when KMS key is provided)
resource "aws_iam_role_policy" "efs_csi_kms_policy" {
  count = var.efs_csi_kms != null ? 1 : 0
  name  = "${var.cluster_name}-efs-csi-kms"
  role  = aws_iam_role.efs_csi_pod_identity.id

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
        Resource = var.efs_csi_kms
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
        Resource = var.efs_csi_kms
      }
    ]
  })
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_eks_addon_version" "efs_csi" {
  addon_name         = "aws-efs-csi-driver"
  kubernetes_version = "1.33"
  most_recent        = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

###############################################################################
# EFS File System
###############################################################################
resource "aws_efs_file_system" "main" {
  creation_token   = "${var.cluster_name}-efs-${var.env}"
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode

  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  encrypted  = true
  kms_key_id = var.efs_csi_kms

  lifecycle_policy {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-efs-${var.env}"
    Environment = var.env
    Terraform   = "true"
    Purpose     = "EFS-Storage"
    Cluster     = var.cluster_name
  })
}

# Security group for EFS mount targets
resource "aws_security_group" "efs_mount_target" {
  name_prefix = "${var.cluster_name}-efs-mt-"
  vpc_id      = var.vpc_id
  description = "Security group for EFS mount targets"

  ingress {
    description = "NFS traffic from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-efs-mount-target-sg"
    Environment = var.env
    Terraform   = "true"
    Purpose     = "EFS-Mount-Target-Security"
    Cluster     = var.cluster_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

# EFS Mount targets
resource "aws_efs_mount_target" "main" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs_mount_target.id]
}

# EFS Access Points
resource "aws_efs_access_point" "access_points" {
  count          = length(var.access_points)
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = var.access_points[count.index].posix_user.gid
    uid = var.access_points[count.index].posix_user.uid
  }

  root_directory {
    path = var.access_points[count.index].path
    creation_info {
      owner_gid   = var.access_points[count.index].creation_info.owner_gid
      owner_uid   = var.access_points[count.index].creation_info.owner_uid
      permissions = var.access_points[count.index].creation_info.permissions
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-${var.access_points[count.index].name}-ap"
    Environment = var.env
    Terraform   = "true"
    Purpose     = "EFS-Access-Point"
    Cluster     = var.cluster_name
  })
}

###############################################################################
# EKS Pod Identity Association and Addon
###############################################################################
# EKS Pod Identity Association for EFS CSI
resource "aws_eks_pod_identity_association" "efs_csi" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "efs-csi-controller-sa"
  role_arn        = aws_iam_role.efs_csi_pod_identity.arn

  tags = merge(var.tags, {
    Environment = var.env
    Terraform   = "true"
    Purpose     = "EFS-CSI-Pod-Identity"
    Cluster     = var.cluster_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EFS CSI Driver Addon
resource "aws_eks_addon" "efs_csi" {
  cluster_name = var.cluster_name
  addon_name   = "aws-efs-csi-driver"

  addon_version               = data.aws_eks_addon_version.efs_csi.version
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_pod_identity_association.efs_csi,
    aws_efs_mount_target.main
  ]

  tags = merge(var.tags, {
    Environment = var.env
    Terraform   = "true"
    Purpose     = "EFS-CSI-Driver"
    Cluster     = var.cluster_name
  })
}

###############################################################################
# Storage Class
###############################################################################
resource "kubectl_manifest" "efs_csi_storage_class" {
  count = var.create_default_storage_class ? 1 : 0

  yaml_body = <<-YAML
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: ${var.storage_class_name}
    labels:
      app.kubernetes.io/managed-by: "terraform"
      environment: ${var.env}
  provisioner: efs.csi.aws.com
  reclaimPolicy: Retain
  volumeBindingMode: Immediate
  allowVolumeExpansion: false
  parameters:
    provisioningMode: efs-ap
    fileSystemId: ${aws_efs_file_system.main.id}
    directoryPerms: "0755"
    gidRangeStart: "1000"
    gidRangeEnd: "2000"
    basePath: "/dynamic_provisioning"
  YAML

  depends_on = [
    aws_eks_addon.efs_csi
  ]
}

# Storage class for existing access points (if any)
resource "kubectl_manifest" "efs_csi_access_point_storage_class" {
  count = length(var.access_points) > 0 ? 1 : 0

  yaml_body = <<-YAML
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: ${var.storage_class_name}-ap
    labels:
      app.kubernetes.io/managed-by: "terraform"
      environment: ${var.env}
  provisioner: efs.csi.aws.com
  reclaimPolicy: Retain
  volumeBindingMode: Immediate
  allowVolumeExpansion: false
  parameters:
    provisioningMode: efs-ap
    fileSystemId: ${aws_efs_file_system.main.id}
    accessPoint: ${aws_efs_access_point.access_points[0].id}
  YAML

  depends_on = [
    aws_eks_addon.efs_csi,
    aws_efs_access_point.access_points
  ]
}