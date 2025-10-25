# S3 Terraform State Bucket Creation

> **🚨 CRITICAL FIRST STEP**: This directory creates the S3 bucket required for Terraform state storage. This **MUST** be deployed before any other components in this repository.

## 📋 Overview

This configuration creates a dedicated S3 bucket that will store Terraform state files for all environments (dev, pro) and global resources in this repository.

### 🎯 Purpose

- **Centralized State**: Single bucket for all Terraform state files
- **Foundation**: Required before any other deployments
- **Security**: Proper bucket configuration with encryption and versioning

## 🚀 Quick Start

### 1. Configure Bucket Settings

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your settings
nano terraform.tfvars
```

### 2. Customize Configuration

```terraform
# Example configuration
region = "eu-central-1"                    # Your AWS region
bucket = "your-unique-terraform-state-2025" # Your unique bucket name
```

### 3. Deploy Bucket

```bash
# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### 4. Update Backend Configurations

After bucket creation, update the bucket name in **ALL** backend.tf files:

```bash
# Files to update with your actual bucket name:
# - ../../environments/dev/backend.tf
# - ../../environments/pro/backend.tf  
# - ../github-oidc/backend.tf (if using CI/CD)
```

## ⚠️ Important Notes

### Bucket Naming Requirements

- **Globally Unique**: S3 bucket names must be globally unique across all AWS accounts
- **DNS Compatible**: Use lowercase letters, numbers, and hyphens only
- **No Underscores**: Avoid underscores in bucket names
- **Meaningful**: Include your organization/project identifier

### Example Naming Patterns

```
# Good examples:
mycompany-terraform-state-2025
projectname-tf-state-prod
acme-corp-infrastructure-state

# Avoid:
terraform-state          # Too generic, likely taken
my_bucket               # Contains underscore
UPPERCASE-BUCKET        # Contains uppercase
```

## 🔧 Configuration Files

| File | Purpose | Action Required |
|------|---------|----------------|
| `main.tf` | S3 bucket configuration | ✅ Ready to use |
| `variables.tf` | Variable definitions | ✅ Ready to use |
| `outputs.tf` | Bucket information outputs | ✅ Ready to use |
| `terraform.tfvars.example` | Example configuration | 📝 Copy and customize |

## 🔒 Security Features

This bucket configuration includes:

- **🔐 Server-side encryption** with AWS managed keys
- **📚 Versioning enabled** for state file history
- **🚫 Public access blocked** by default
- **🏷️ Consistent tagging** for resource management

## 🆘 Troubleshooting

### Common Issues

#### Bucket Name Already Exists
```
Error: bucket already exists
```
**Solution**: Choose a more unique bucket name in `terraform.tfvars`

#### Insufficient Permissions
```
Error: Access Denied
```
**Solution**: Ensure your AWS credentials have S3 bucket creation permissions:
- `s3:CreateBucket`
- `s3:PutBucketPolicy`
- `s3:PutBucketVersioning`
- `s3:PutEncryptionConfiguration`

#### Region Mismatch
```
Error: bucket region mismatch
```
**Solution**: Ensure the region in `terraform.tfvars` matches your AWS CLI region

## 🔄 Next Steps

After successful bucket creation:

1. **✅ Bucket Created**: S3 bucket is ready for Terraform state storage
2. **📝 Update Backends**: Update bucket names in all `backend.tf` files  
3. **🚀 Deploy Environments**: Proceed with environment deployments
4. **🔗 Optional CI/CD**: Deploy GitHub OIDC provider if needed

## 📚 Related Documentation

- **Main Repository**: [../../README.md](../../README.md) - Full deployment guide
- **Environment Deployment**: [../../environments/](../../environments/) - Dev/Pro configurations  
- **GitHub OIDC Setup**: [../github-oidc/README.md](../github-oidc/README.md) - CI/CD configuration

---

**⚠️ Remember**: This is the foundation step - all other deployments depend on this bucket!