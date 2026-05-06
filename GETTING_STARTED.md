# Clone-To-Deploy Guide

This repository is intended to work as a template: clone it, replace example values, then deploy.

## What You Must Have First

- An AWS account with permissions to create IAM, VPC, EKS, Route53, S3, ECR, and load balancer resources.
- AWS CLI authenticated locally or in CI.
- Terraform, kubectl, Helm, and Task installed.
- A real domain delegated to Route53.

## Files You Change

For a normal `dev` deployment, these are the only files you should need to create from examples:

```bash
cp global/create-bucket/terraform.tfvars.example global/create-bucket/terraform.tfvars
cp environments/dev/backend.hcl.example environments/dev/backend.hcl
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

Edit the copied files and replace:

- `region`
- `bucket`
- `cluster_name`
- `hosted_zone_id`
- `domain_name`
- `subject_alternative_names`
- `acme_email`
- subnet CIDRs if the defaults conflict with your network plan
- `additional_allowed_ips` if `restrict_cluster_access = true`

Keep `backend.hcl` and `terraform.tfvars` uncommitted. They are ignored by Git.

## Deploy Order

1. Create the Terraform state bucket:

```bash
cd global/create-bucket
terraform init
terraform apply
```

2. Configure the backend for the target environment:

```bash
cd ../../environments/dev
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Or from the repository root:

```bash
task deploy-infrastructure ENV=dev
```

## Optional GitHub Actions Access

By default, EKS access for GitHub Actions is disabled so a first deployment does not require the OIDC role to exist.

To enable it:

```bash
cp global/github-oidc/backend.hcl.example global/github-oidc/backend.hcl
cp global/github-oidc/terraform.tfvars.example global/github-oidc/terraform.tfvars
```

Deploy `global/github-oidc`, then set this in your environment `terraform.tfvars`:

```hcl
enable_github_actions_access = true
github_actions_role_name     = "github-actions"
```

## Things That Cannot Be Only Variables

- Route53 delegation must be done at your domain registrar if the domain is not registered in Route53.
- Terraform backend settings must be supplied through `backend.hcl` because Terraform does not allow normal variables in backend blocks.
- DNS and Let's Encrypt certificate issuance require public DNS propagation before services become reachable.
