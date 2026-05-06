# Infrastructure Modules

This directory contains reusable Terraform modules for AWS infrastructure components used across different environments.

## 📦 Available Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| **[eks-karpenter](./eks-karpenter/)** | Complete EKS cluster with Karpenter auto-scaling | EKS 1.33, Karpenter, Traefik, ArgoCD, External DNS |
| **[ebs-csi](./ebs-csi/)** | EBS CSI driver with Pod Identity | Pod Identity auth, KMS encryption, GP3 storage classes |
| **[efs-csi](./efs-csi/)** | EFS CSI driver with Pod Identity | Shared storage, Multi-AZ, Access points, KMS encryption |
| **[kms-key](./kms-key/)** | Customer-managed KMS keys | Encryption for EBS/EFS, Key rotation, Cluster integration |
| **[ecr](./ecr/)** | Container registries for applications | Private registries, Lifecycle policies, GitHub integration |
| **[s3](./s3/)** | S3 buckets for state and data storage | Encryption, Versioning, Security best practices |
| **[github-oidc-provider](./github-oidc-provider/)** | GitHub Actions AWS integration | OIDC authentication, No long-lived credentials |
| **[aws_iam](./aws_iam/)** | IAM users and cross-account access | Multi-account access, Role assumptions, User management |
| **[aws_organizations](./aws_organizations/)** | AWS Organizations management | Multi-account setup, OUs, Service control policies |

## 🏗️ Architecture Overview

The modules are designed to work together to create a complete AWS infrastructure:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   S3 + KMS      │    │  ECR Registry   │    │ GitHub OIDC     │
│   (State)       │    │  (Images)       │    │ (CI/CD Auth)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
              ┌─────────────────────────────────────┐
              │           EKS Cluster               │
              │  ┌─────────────┐  ┌─────────────┐   │
              │  │  EBS CSI    │  │  EFS CSI    │   │
              │  │  (Block)    │  │  (Shared)   │   │
              │  └─────────────┘  └─────────────┘   │
              │         │              │           │
              │  ┌─────────────────────────────┐   │
              │  │       Karpenter             │   │
              │  │   (Auto Scaling)            │   │
              │  └─────────────────────────────┘   │
              └─────────────────────────────────────┘
                                 │
              ┌─────────────────────────────────────┐
              │        AWS Organizations            │
              │  ┌─────────────┐  ┌─────────────┐   │
              │  │    Dev OU   │  │   Pro OU    │   │
              │  └─────────────┘  └─────────────┘   │
              └─────────────────────────────────────┘
```

## 🔧 Usage Patterns

### Basic EKS Setup
```hcl
# Core infrastructure
module "s3" { source = "./modules/s3" }
module "kms" { source = "./modules/kms-key" }
module "ecr" { source = "./modules/ecr" }

# EKS cluster with storage
module "eks" { source = "./modules/eks-karpenter" }
module "ebs_csi" { source = "./modules/ebs-csi" }
module "efs_csi" { source = "./modules/efs-csi" }
```

### Multi-Account Setup
```hcl
# Organization management
module "organizations" { source = "./modules/aws_organizations" }
module "iam_users" { source = "./modules/aws_iam" }

# CI/CD integration
module "github_oidc" { source = "./modules/github-oidc-provider" }
```

## 🛡️ Security Features

- **Pod Identity**: Modern EKS authentication for AWS services
- **KMS Encryption**: Customer-managed keys for data protection  
- **IP Restrictions**: Configurable access control per environment
- **OIDC Authentication**: Secure CI/CD without long-lived credentials
- **Cross-Account Access**: Proper IAM role assumptions
- **Network Security**: Private subnets and security groups

## 📋 Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- kubectl for EKS management
- Helm for Kubernetes package management

## 🚀 Getting Started

1. **Choose your modules** based on requirements
2. **Configure variables** in your environment
3. **Apply in order** (dependencies matter)
4. **Validate deployment** using outputs

See individual module README files for detailed usage instructions.