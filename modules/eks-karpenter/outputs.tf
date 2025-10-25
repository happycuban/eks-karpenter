output "eks_cluster_info" {
  description = "Comprehensive EKS cluster information and setup details"
  value       = <<EOF
###################################### KUBECONFIG ###########################################

        aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_name}

############################# INDIVIDUAL OUTPUTS (for scripts/automation) ###############
        cluster_name                           = "${module.eks.cluster_name}"
        cluster_version                        = "${module.eks.cluster_version}"
        cluster_endpoint                       = "${module.eks.cluster_endpoint}"
        traefik_dns_managed_by                 = "ExternalDNS will create *.${var.domain_name} pointing to Traefik LoadBalancer"

############################# N E T W O R K I N G ###########################################
        VPC ID                                  ${module.vpc.vpc_id}
        Public subnets                          ${join(", ", module.vpc.public_subnets)}
        Private subnets                         ${join(", ", module.vpc.private_subnets)}
        Intra subnets                           ${join(", ", module.vpc.intra_subnets)}
        NAT Gateway                             ${module.vpc.natgw_ids[0]}
        Internet Gateway                        ${module.vpc.igw_id}

###################################### EKS CLUSTER #####################################################
        Cluster Name                            ${module.eks.cluster_name}
        Cluster Version                         ${module.eks.cluster_version}
        Cluster Endpoint                        ${module.eks.cluster_endpoint}
        Cluster Security Group                  ${module.eks.cluster_primary_security_group_id}
        Node Security Group                     ${module.eks.node_security_group_id}
        OIDC Provider                           ${module.eks.oidc_provider}
        OIDC Provider ARN                       ${module.eks.oidc_provider_arn}

        Access Entries Summary:
%{for k, v in module.eks.access_entries~}
        - ${k}: ${v.principal_arn}
%{endfor~}

############################# IAM ROLES & POD IDENTITY ###################################
        EKS Cluster Role                        ${module.eks.cluster_iam_role_arn}
        EKS Nodes Role                          ${module.eks.eks_managed_node_groups["karpenter"].iam_role_arn}
        
        AWS Load Balancer Controller Role      ${aws_iam_role.aws_lbc.arn}
        AWS Load Balancer Controller Policy    ${aws_iam_policy.aws_lbc.arn}
        
        ExternalDNS Role                       ${aws_iam_role.external_dns.arn}
        ExternalDNS Policy                     ${aws_iam_policy.external_dns.arn}
        
        cert-manager Role                      ${aws_iam_role.cert_manager.arn}
        cert-manager Route53 Policy           ${aws_iam_policy.cert_manager_route53.arn}
        
        ArgoCD Image Updater Role              ${aws_iam_role.argocd_image_updater.arn}
        
        Karpenter Controller Role              ${module.karpenter.iam_role_arn}
        Karpenter Node Role                    ${module.karpenter.node_iam_role_arn}

############################# HELM RELEASES & ADDONS ####################################
        Karpenter Version                      1.8.0 (Deployed via Helm)
        AWS Load Balancer Controller Version  1.13.4 (Deployed via Helm)
        ExternalDNS Version                    1.15.0 (Deployed via Helm)
        Traefik Version                        34.4.1 (Deployed via Helm)
        cert-manager Version                   v1.17.1 (Deployed via Helm)
        ArgoCD Version                         8.5.8 (Deployed via Helm)
        ArgoCD Image Updater Version           0.12.3 (Deployed via Helm)

############################# DNS & CERTIFICATES ########################################
        Domain                                 ${var.domain_name}
        Route53 Hosted Zone ID                 ${var.hosted_zone_id}
        DNS Management                         ExternalDNS (automatic via annotations)
        Certificate Management                 cert-manager + Let's Encrypt
        Certificate Issuer                     cert-manager-acme-route53-issuer
        Wildcard Certificate                   ${var.subject_alternative_names} (via cert-manager)

############################# SERVICE URLS ###############################################
        ArgoCD Web UI                          https://argocd.${var.domain_name}
        Traefik Dashboard                      https://traefik-dashboard.${var.domain_name}/dashboard

############################# ACCESS & SECURITY #########################################
        Pod Identity Agent                     Enabled (for secure AWS access)
        GitHub Actions Role                    github-actions (EKS access configured)
        Personal Access                        tf-playground (cluster admin)
        Manager Role                           eks-admin
        Developer User                         eks-developer

############################# USAGE EXAMPLES #############################################
        
        # Check cluster status
        kubectl get nodes
        kubectl get pods -A
        
        # Check Helm releases
        helm list -A
        
        # Check ExternalDNS logs
        kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns
        
        # Add DNS record to any service (ExternalDNS will manage it)
        kubectl annotate service <service-name> external-dns.alpha.kubernetes.io/hostname=myapp.${var.domain_name}
        
        # Check certificates
        kubectl get certificates -A
        kubectl get clusterissuers
        
        # Access ArgoCD
        # Web UI: https://argocd.${var.domain_name}
        # Default user: admin, get password: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d

############################# TERRAFORM OUTPUTS (for automation) ########################
        
        # Use these in scripts or other Terraform modules:
        cluster_name     = "${module.eks.cluster_name}"
        cluster_version  = "${module.eks.cluster_version}"
        cluster_endpoint = "${module.eks.cluster_endpoint}"
        
    EOF
}

# Individual outputs for module consumption
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint for kubectl provider"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for kubectl provider"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}