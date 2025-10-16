# Global Infrastructure - Deploy First

> **⚠️ PREREQUISITES**: This global infrastructure **MUST** be deployed before the EKS cluster. It provides essential services required for EKS deployment and CI/CD operations.

This directory contains the foundational infrastructure components that need to be deployed once per AWS account/organization.

## 📁 Directory Structure

```
global/
├── s3/             # Terraform state bucket
├── iam/            # GitHub Actions OIDC and IAM roles
├── ecr/            # Container registries
├── global.tfvars   # Configuration variables
├── state.config    # Backend configuration
└── COMMANDS.md     # Deployment commands
```

## 🚀 Quick Setup

> **⚠️ IMPORTANT**: Replace all placeholder values in configuration files before deployment.

### 1. Configure Variables
```bash
# Copy and customize the configuration
cp global.tfvars.example global.tfvars
cp state.config.example state.config  # If needed

# Edit the files with your actual values:
# - AWS region
# - S3 bucket name
# - GitHub repositories
```
## 🎯 Why Deploy Global First?

The EKS cluster deployment requires:
- **S3 bucket** for storing Terraform state
- **ECR repositories** for container images used by workloads
- **OIDC integration** for GitHub Actions to deploy applications

## 📊 Components

### 1. S3 Bucket (`s3/`) - Foundation
- 🗄️ Encrypted S3 bucket for Terraform state storage
- 🔒 Versioning enabled with public access blocked
- 📍 **Deploy first** - Required for all subsequent deployments

### 2. IAM Roles (`iam/`) - Access Control  
- 🔐 GitHub Actions OIDC provider and federated access
- 📦 ECR push/pull permissions for CI/CD
- 🛡️ Least-privilege IAM policies for deployments
- 📍 **Deploy after S3** - Needs state bucket

### 3. ECR Repositories (`ecr/`) - Container Registry
- 🐳 Private container registries for each GitHub repository
- 🔄 Lifecycle policies for automatic image cleanup
- 🚀 Ready for EKS workloads and applications
- 📍 **Deploy after IAM** - Needs OIDC permissions

## 🔧 Configuration Files

### `global.tfvars`
Main configuration file containing:
- AWS region
- S3 bucket name for Terraform state
- List of GitHub repositories

### `state.config`
Backend configuration for Terraform state:
- S3 bucket and region
- State file encryption

## � Deployment Commands

**IMPORTANT**: Run these commands in the exact order shown:

```bash
# Step 1: Deploy S3 bucket for Terraform state
cd global/s3
terraform init
terraform apply -var-file=../global.tfvars

# Step 2: Migrate state to S3 backend  
terraform init -migrate-state -backend-config=../state.config

# Step 3: Deploy IAM roles and OIDC provider
cd ../iam
terraform init -backend-config=../state.config
terraform apply -var-file=../global.tfvars

# Step 4: Deploy ECR repositories
cd ../ecr
terraform init -backend-config=../state.config
terraform apply -var-file=../global.tfvars

# Return to root for EKS deployment
cd ../../
```

## �🛡️ Security

- All Terraform state is encrypted at rest
- IAM roles use least-privilege principles
- ECR repositories are private by default
- GitHub Actions uses OIDC (no long-lived secrets)

## 📝 Deployment Flow

### Complete the global setup first:
```bash
# 1. Deploy foundational infrastructure
cd global/
# Follow the deployment steps in COMMANDS.md
```

### Then deploy EKS cluster:
```bash
# 2. Deploy EKS cluster (from root directory)
cd ../
terraform init
terraform apply
```

## ✅ What You Get

After deploying global infrastructure:

1. **🔐 OIDC Integration**: GitHub Actions can deploy to AWS securely (no API keys!)
2. **📦 Container Registry**: ECR repositories ready for your application images
3. **🗄️ State Management**: Centralized Terraform state storage in S3
4. **🚀 EKS Ready**: All prerequisites satisfied for EKS cluster deployment

## 🔍 Troubleshooting

### Common Issues

1. **State bucket doesn't exist**: Deploy `s3/` module first
2. **Permission denied**: Check IAM role policies and trust relationships
3. **ECR push fails**: Verify GitHub Actions has correct repository permissions

### Useful Commands

```bash
# Check current state
terraform show

# List ECR repositories
aws ecr describe-repositories

# Verify IAM role
aws sts assume-role --role-arn <role-arn> --role-session-name test
```