# GitHub OIDC Provider - Optional CI/CD Setup

> **ℹ️ OPTIONAL**: This GitHub OIDC provider setup is only needed if you want to use GitHub Actions for CI/CD deployments. You can skip this and deploy the EKS cluster directly.

This directory contains the GitHub OpenID Connect (OIDC) provider setup for secure, keyless authentication from GitHub Actions to AWS.

## 📁 Directory Structure

```
global/
└── github-oidc/                    # GitHub OIDC provider setup
    ├── main.tf                     # OIDC provider configuration
    ├── variables.tf               # Variable definitions
    ├── outputs.tf                 # Output values
    ├── backend.tf                 # S3 backend configuration
    └── terraform.tfvars.example   # Example variables (COPY & CUSTOMIZE)
```

## 🚀 Quick Setup

> **ℹ️ IMPORTANT**: This is optional and only needed if you want to use GitHub Actions for CI/CD.

### 1. Configure Variables
```bash
cd global/github-oidc

# Copy and customize the configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your actual values:
# - AWS region
# - S3 bucket name for Terraform state
# - GitHub repositories for OIDC access
```

### 2. Deploy OIDC Provider
```bash
terraform init
terraform plan
terraform apply
```

## 🎯 What This Provides

The GitHub OIDC provider enables:
- **Keyless Authentication**: No AWS credentials stored in GitHub secrets
- **Secure CI/CD**: GitHub Actions can deploy to AWS using short-lived tokens
- **Role-Based Access**: Fine-grained permissions for different repositories

## � Configuration Files

The GitHub OIDC setup uses standard Terraform configuration files:

| File | Purpose | Required |
|------|---------|----------|
| `terraform.tfvars.example` | Example variables (copy to `terraform.tfvars`) | ✅ Yes |
| `terraform.tfvars` | Your actual configuration values | ✅ Yes (create from example) |
| `main.tf` | GitHub OIDC provider configuration | ✅ Yes (provided) |
| `variables.tf` | Variable definitions | ✅ Yes (provided) |
| `backend.tf` | S3 backend for Terraform state | ✅ Yes (provided) |
| `outputs.tf` | Output values after deployment | ✅ Yes (provided) |

### Example Configuration (`terraform.tfvars`)

```terraform
# AWS Configuration
region = "eu-central-1"  # Your AWS region
bucket = "github-terraform-state-2025"  # Must match backend.tf bucket name

# GitHub Repositories (replace with your actual repos)
github_repos = [
  "your-apps-repository",
  "your-infrastructure-repository"
]
```

> **⚠️ CRITICAL**: The `bucket` name in your `terraform.tfvars` **must exactly match** the hardcoded `bucket` name in `backend.tf`. Terraform backend configuration cannot use variables!

---

## 🚀 Deployment

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed

### Steps

```bash
# Navigate to GitHub OIDC directory
cd global/github-oidc

# Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual values

# Deploy the OIDC provider
terraform init
terraform plan
terraform apply
```

## ✅ What You Get

After deploying the GitHub OIDC provider:

1. **🔐 Keyless CI/CD**: GitHub Actions can authenticate to AWS without storing credentials
2. **🛡️ Secure Access**: Short-lived tokens with fine-grained permissions
3. **📦 Repository Access**: Configured access for your specified GitHub repositories
4. **🚀 Ready for Automation**: EKS cluster deployments can now use GitHub Actions

## 🔧 Usage with GitHub Actions

After deployment, your GitHub Actions workflows can authenticate like this:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/github-actions
    role-session-name: GitHub_to_AWS_via_FederatedOIDC
    aws-region: eu-central-1
```

## 🔍 Troubleshooting

### Common Issues

1. **S3 backend error**: Verify the bucket name in `terraform.tfvars` matches `backend.tf` (buckets are created automatically)
2. **Permission denied**: Check AWS credentials have IAM permissions to create OIDC providers and S3 buckets
3. **GitHub Actions fails**: Verify repository names in `terraform.tfvars` match your actual repos

### Useful Commands

```bash
# Check OIDC provider
aws iam list-open-id-connect-providers

# Verify role trust policy
aws iam get-role --role-name github-actions

# Test assume role (replace with actual role ARN)
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::123456789012:role/github-actions \
  --role-session-name test \
  --web-identity-token <github-token>
```

