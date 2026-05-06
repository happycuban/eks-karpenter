# Agent Notes

## Repo Purpose
- This is a Terraform template repo for cloning, replacing example values, and deploying an EKS/Karpenter stack; keep changes template-friendly and avoid committing real account/domain values.
- Main deployable roots are `global/create-bucket`, `global/github-oidc`, `global/repos-ecr`, `environments/dev`, and `environments/pro`; shared logic lives under `modules/`.

## Setup And Deploy Order
- Terraform state bucket must be created first from `global/create-bucket` before any environment uses the S3 backend.
- Real deploys require copying both value files: `terraform.tfvars.example -> terraform.tfvars` and `backend.hcl.example -> backend.hcl` in the target root.
- Do not hardcode backend values in `backend.tf`; backends are intentionally empty and initialized with `terraform init -backend-config=backend.hcl`.
- `terraform.tfvars` and `backend.hcl` are ignored and should stay uncommitted; update the corresponding `.example` files for template changes.
- GitHub Actions EKS access is disabled by default via `enable_github_actions_access = false`; deploy `global/github-oidc` or provide an existing role before enabling it.

## Commands
- Format all Terraform: `terraform fmt -recursive .`
- Validate all environments without remote backend: `task validate-terraform`
- Validate one environment: `terraform init -backend=false && terraform validate` from `environments/dev` or `environments/pro`.
- Initialize for a real environment: `terraform init -backend-config=backend.hcl` from that environment directory.
- Normal dev deploy shortcut: `task deploy-infrastructure ENV=dev`; it uses `backend.hcl` when present, then plans, prompts, applies, and runs `update-kubeconfig`.
- Cluster diagnostics are Taskfile-based: `task check-cluster-health`, `task check-karpenter`, `task check-traefik`, `task check-certificates`, `task check-oidc`.

## Terraform/Provider Gotchas
- The EKS module uses AWS CLI exec auth in the `helm`, `kubectl`, and `kubernetes` providers; local AWS credentials and `aws eks get-token` must work for apply-time Kubernetes resources.
- `modules/eks-karpenter/providers.tf` includes an aliased `aws.virginia` provider for ECR Public auth; do not remove it just because the cluster region is configurable.
- `modules/eks-karpenter/main.tf` hardcodes Kubernetes `1.33`, VPC CIDR `10.0.0.0/16`, and AZ suffixes `${region}a/b/c`; changing those is a real behavior change, not just template cleanup.
- ArgoCD Image Updater values are templated at `modules/eks-karpenter/values/image-updater.yaml.tpl`; keep account ID and region dynamic there.

## CI And Releases
- `.github/workflows/eks-terraform.yml.example` is inactive by design; activating it requires renaming to `eks-terraform.yml` and replacing AWS account/region placeholders.
- The active release workflow runs semantic-release on pushes to `main` that touch `*.tf`, `*.tpl`, or `.github/workflows/release.yaml`; use conventional commit messages when changing infrastructure files.

## File Hygiene
- `.gitattributes` forces LF line endings; avoid CRLF-only churn.
- `.terraform.lock.hcl` is currently ignored even though lockfiles exist in environment dirs; do not rely on lockfile changes being tracked unless `.gitignore` is changed intentionally.
