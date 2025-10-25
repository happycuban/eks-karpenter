# ECR Module

This module creates Amazon Elastic Container Registry (ECR) repositories with automated lifecycle policies and GitHub Actions integration.

## Features

- **Private Registries**: Secure container image storage
- **Lifecycle Policies**: Automated image cleanup and retention
- **GitHub Integration**: OIDC authentication for CI/CD pipelines
- **Multi-Repository**: Support for multiple application repositories
- **Cost Optimization**: Intelligent image lifecycle management

## Key Components

- ECR repositories for each application
- Lifecycle policies for image retention
- IAM policies for GitHub Actions access
- Cross-account access policies (if needed)

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr"
  
  region       = "eu-central-1"
  bucket       = "my-terraform-state"
  github_repos = [
    "myorg/app1",
    "myorg/app2",
    "myorg/app3"
  ]
}
```

## Variables

- `region`: AWS region for ECR repositories
- `bucket`: S3 bucket name for state management
- `github_repos`: List of GitHub repositories requiring ECR access

## Outputs

- `ecr_repository_urls`: Map of repository names to their URLs
- `ecr_repository_arns`: Map of repository names to their ARNs