# EKS Karpenter Module

This module creates a complete Amazon EKS cluster with Karpenter auto-scaling, essential add-ons, and security configurations.

## Features

- **EKS Cluster**: Kubernetes 1.33 with managed node groups and Fargate profiles
- **Karpenter**: Intelligent node provisioning and auto-scaling
- **Security**: IP-based access control with configurable restrictions
- **Networking**: External DNS, AWS Load Balancer Controller, Traefik ingress
- **Monitoring**: ArgoCD for GitOps, image updater for automated deployments
- **Storage**: Integration with EBS and EFS CSI drivers via Pod Identity

## Key Components

- EKS cluster with public/private endpoint access
- Karpenter for efficient node provisioning
- Traefik as ingress controller with middleware support
- ArgoCD for GitOps workflows
- External DNS for automatic DNS management
- AWS Load Balancer Controller for ALB/NLB provisioning

## Security Features

- IP-based access control with `restrict_cluster_access` variable
- Cross-namespace middleware support for granular access control
- Pod Identity integration for secure AWS service access
- Configurable allowed IP ranges per environment

## Usage

```hcl
module "eks_karpenter" {
  source = "../../modules/eks-karpenter"
  
  region                    = "eu-central-1"
  env                      = "dev"
  cluster_name             = "my-cluster"
  hosted_zone_id           = "Z123456789"
  private_subnets          = ["subnet-123", "subnet-456"]
  public_subnets           = ["subnet-789", "subnet-abc"]
  intra_subnets           = ["subnet-def", "subnet-ghi"]
  additional_allowed_ips   = ["10.0.0.0/8"]
  domain_name              = "happycuban-example.dk"
  restrict_cluster_access  = false
}
```

## Variables

- `restrict_cluster_access`: Enable IP restrictions (default: false)
- `domain_name`: Base domain for DNS records
- `additional_allowed_ips`: Environment-specific allowed IP ranges
- `subject_alternative_names`: Additional certificate SANs

## Outputs

- `cluster_endpoint`: EKS cluster API endpoint
- `cluster_name`: Name of the created EKS cluster
- `cluster_certificate_authority_data`: Base64 encoded CA certificate