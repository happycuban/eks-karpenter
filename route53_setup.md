# 🌐 Route53 DNS Configuration Guide

This guide provides comprehensive instructions for configuring AWS Route53 for your EKS cluster deployment.

---

## 📋 Prerequisites

Before you begin, ensure you have:
- [ ] AWS Account with admin or appropriate IAM permissions
- [ ] AWS CLI configured (`aws configure`)
- [ ] A registered domain name (can be registered through Route53 or external registrar)
- [ ] Access to your domain registrar's DNS settings (if using external registrar)

---

## 🎯 Overview

This EKS deployment requires a Route53 hosted zone for automated DNS management. The cluster uses:
- **ExternalDNS**: Automatically creates DNS records for load balancers and ingress resources
- **cert-manager**: Provisions SSL/TLS certificates via Let's Encrypt using DNS validation
- **Wildcard DNS**: Supports `*.happycuban-example.dk` for all services (ArgoCD, Traefik, applications)

---

## 🌐 Domain Configuration Options

### Option A: Domain Registered with Route53 (Easiest)

If you register your domain directly through Route53, AWS automatically creates and configures the hosted zone.

#### Step 1: Purchase Domain in Route53

```bash
# Check domain availability
aws route53domains check-domain-availability --domain-name happycuban-example.dk

# Register domain (this creates the hosted zone automatically)
aws route53domains register-domain \
  --domain-name happycuban-example.dk \
  --duration-in-years 1 \
  --admin-contact file://contact-info.json \
  --registrant-contact file://contact-info.json \
  --tech-contact file://contact-info.json
```

<details>
<summary><b>View contact-info.json example</b></summary>

```json
{
  "FirstName": "Happy",
  "LastName": "Cuban",
  "ContactType": "PERSON",
  "OrganizationName": "Happy Corp",
  "AddressLine1": "123 Main Street",
  "City": "Seattle",
  "State": "WA",
  "CountryCode": "US",
  "ZipCode": "98101",
  "PhoneNumber": "+1.2065551234",
  "Email": "admin@happycuban-example.dk"
}
```
</details>

Or via AWS Console:
1. Navigate to [Route53 Console](https://console.aws.amazon.com/route53/)
2. Go to **Registered domains** → **Register domain**
3. Search for your desired domain
4. Complete the registration wizard
5. AWS automatically creates the hosted zone

#### Step 2: Get Your Hosted Zone ID

```bash
# List all hosted zones
aws route53 list-hosted-zones-by-name

# Find specific zone
aws route53 list-hosted-zones-by-name --dns-name happycuban-example.dk

# Extract just the ID
aws route53 list-hosted-zones --query "HostedZones[?Name=='happycuban-example.dk.'].Id" --output text
# Output: /hostedzone/Z1234EXAMPLE5678
# Use only: Z1234EXAMPLE5678
```

Or via AWS Console:
1. Go to [Route53 Hosted Zones](https://console.aws.amazon.com/route53/v2/hostedzones)
2. Click on your domain
3. Copy the **Hosted zone ID** from the top right

---

### Option B: Domain Registered with External Registrar (GoDaddy, Namecheap, etc.)

If you already own a domain through another registrar, you'll need to delegate DNS to Route53.

#### Step 1: Create Route53 Hosted Zone

```bash
# Using AWS CLI
aws route53 create-hosted-zone \
  --name happycuban-example.dk \
  --caller-reference $(date +%s) \
  --hosted-zone-config Comment="EKS cluster domain"
```

Or via AWS Console:
1. Open [Route53 Console](https://console.aws.amazon.com/route53/)
2. Click **"Create hosted zone"**
3. Enter your **domain name** (e.g., `happycuban-example.dk`)
4. Choose **"Public hosted zone"**
5. Click **"Create hosted zone"**

#### Step 2: Get Route53 Nameservers

After creating the hosted zone, AWS provides 4 nameservers:

```bash
# Get nameservers for your hosted zone
aws route53 get-hosted-zone --id Z1234EXAMPLE5678

# Output includes NameServers like:
# ns-1234.awsdns-12.org
# ns-5678.awsdns-34.com
# ns-910.awsdns-56.net
# ns-1112.awsdns-78.co.uk
```

Or via AWS Console:
1. Click on your hosted zone
2. Note the 4 **NS (Name Server)** records

#### Step 3: Update Domain Registrar Nameservers

Update your domain's nameservers at your registrar to point to Route53:

<details>
<summary><b>📘 GoDaddy Instructions</b></summary>

1. Log into [GoDaddy](https://www.godaddy.com/)
2. Go to **My Products** → **Domains**
3. Click **DNS** next to your domain
4. Scroll to **Nameservers** → Click **Change**
5. Select **"Custom"** nameservers
6. Enter all 4 AWS nameservers (one per field)
7. Click **Save**
8. **⏱️ Propagation**: 24-48 hours

</details>

<details>
<summary><b>📗 Namecheap Instructions</b></summary>

1. Log into [Namecheap](https://www.namecheap.com/)
2. Go to **Domain List** → Click **Manage** on your domain
3. Under **Nameservers**, select **Custom DNS**
4. Enter all 4 AWS nameservers
5. Click the green checkmark to save
6. **⏱️ Propagation**: 24-48 hours

</details>

<details>
<summary><b>📙 Google Domains Instructions</b></summary>

1. Log into [Google Domains](https://domains.google.com/)
2. Click on your domain
3. Go to **DNS** → **Name servers**
4. Select **"Use custom name servers"**
5. Enter all 4 AWS nameservers
6. Click **Save**
7. **⏱️ Propagation**: 24-48 hours

</details>

<details>
<summary><b>📕 Cloudflare Instructions</b></summary>

> **Note**: If you use Cloudflare for DNS, you must either:
> - **Option 1**: Migrate DNS to Route53 (recommended for this EKS setup)
> - **Option 2**: Keep Cloudflare but disable proxy (DNS-only mode) for EKS-related records

**To migrate to Route53:**
1. Export your DNS records from Cloudflare
2. Create Route53 hosted zone
3. Import DNS records to Route53
4. Update nameservers at your registrar to Route53 nameservers
5. Remove domain from Cloudflare

</details>

#### Step 4: Verify DNS Delegation

Wait 5-10 minutes after updating nameservers, then verify:

```bash
# Check nameservers (should show AWS nameservers)
dig NS happycuban-example.dk +short

# Expected output:
# ns-1234.awsdns-12.org.
# ns-5678.awsdns-34.com.
# ns-910.awsdns-56.net.
# ns-1112.awsdns-78.co.uk.

# Alternative: use nslookup
nslookup -type=NS happycuban-example.dk

# Online verification tools:
# https://www.whatsmydns.net/
# https://dnschecker.org/
```

⚠️ **Important**: DNS propagation can take up to 48 hours. Don't proceed with EKS deployment until nameservers are fully propagated.

#### Step 5: Get Hosted Zone ID

```bash
# Using AWS CLI
aws route53 list-hosted-zones --query "HostedZones[?Name=='happycuban-example.dk.'].Id" --output text

# Output: /hostedzone/Z1234EXAMPLE5678
# Copy only the ID part: Z1234EXAMPLE5678
```

Or via AWS Console:
1. Go to [Route53 Hosted Zones](https://console.aws.amazon.com/route53/v2/hostedzones)
2. Click on your domain
3. Copy the **Hosted zone ID** (e.g., `Z1234EXAMPLE5678`)

---

## 🔍 Finding Configuration Values

### Hosted Zone ID

```bash
# Method 1: List all and filter
aws route53 list-hosted-zones --query "HostedZones[?Name=='happycuban-example.dk.'].Id" --output text

# Method 2: Using jq for cleaner output
aws route53 list-hosted-zones-by-name --dns-name happycuban-example.dk \
  | jq -r '.HostedZones[0].Id' | cut -d'/' -f3

# Method 3: AWS Console
# Route53 → Hosted zones → Click domain → Copy "Hosted zone ID"
```

### AWS Region Selection

```bash
# List all available regions
aws ec2 describe-regions --output table

# Common regions for EKS:
# us-east-1      - US East (N. Virginia) - Lowest cost, most AWS services
# us-west-2      - US West (Oregon) - Popular for production
# eu-central-1   - Europe (Frankfurt)
# eu-west-1      - Europe (Ireland)
# ap-southeast-1 - Asia Pacific (Singapore)
# ap-northeast-1 - Asia Pacific (Tokyo)

# Choose based on:
# 1. User proximity (latency)
# 2. Compliance requirements (data residency)
# 3. Cost (pricing varies by region)
```

---

## 📝 Update Terraform Configuration

After setting up Route53, update your `environments/dev/terraform.tfvars`:

```terraform
###############################################################################
# DNS Configuration
# CRITICAL: Get these values from Route53
###############################################################################

# Your Route53 hosted zone ID (without /hostedzone/ prefix)
hosted_zone_id = "Z1234EXAMPLE5678"

# Your actual domain name (without trailing dot)
domain_name = "happycuban-example.dk"

# Wildcard certificate for all subdomains
subject_alternative_names = "*.happycuban-example.dk"
```

### Complete Example Configuration

```terraform
# environments/dev/terraform.tfvars

###############################################################################
# AWS Configuration
###############################################################################
region = "us-west-2"  # Choose your preferred region
bucket = "demo-terraform-state-2025"  # Must be globally unique

###############################################################################
# EKS Cluster Configuration
###############################################################################
cluster_name = "happy-eks-cluster"

###############################################################################
# DNS Configuration (FROM ROUTE53)
###############################################################################
hosted_zone_id = "Z0123456789ABCDEFGHIJ"  # Your hosted zone ID
domain_name    = "happycuban-example.dk"          # Your domain
subject_alternative_names = "*.happycuban-example.dk"  # Wildcard certificate

###############################################################################
# Environment & Project
###############################################################################
environment  = "dev"
project_name = "demo-infrastructure"

###############################################################################
# Network Configuration
###############################################################################
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
intra_subnets   = ["10.0.104.0/24", "10.0.105.0/24", "10.0.106.0/24"]
```

> **⚠️ CRITICAL**: The `bucket` name in `terraform.tfvars` must match the hardcoded bucket in `backend.tf`

---

## 🚨 Common Pitfalls and Solutions

| Issue | Problem | Solution |
|-------|---------|----------|
| **DNS Not Resolving** | Nameservers not updated or propagation incomplete | Wait 24-48 hours after updating nameservers. Verify with `dig NS happycuban-example.dk` |
| **Wrong Zone ID Format** | Copied ID includes `/hostedzone/` prefix | Remove prefix, use only `Z1234EXAMPLE5678` format |
| **Trailing Dot in Domain** | Used `happycuban-example.dk.` with trailing dot | Use `happycuban-example.dk` without trailing dot in terraform.tfvars |
| **Wrong Zone Type** | Created private hosted zone instead of public | Hosted zone must be **public** for internet-accessible services |
| **Mismatched Domain** | Zone for `happycuban-example.dk` but config uses `demo.com` | Domain in tfvars must exactly match hosted zone name |
| **Certificate Validation Fails** | cert-manager can't validate domain ownership | Ensure Route53 hosted zone exists and DNS is fully delegated |
| **ExternalDNS Not Creating Records** | IAM permissions missing or zone ID incorrect | Verify EKS pod identity has Route53 permissions and zone ID is correct |
| **Nameserver Not Propagated** | Applied config before DNS delegation complete | Wait for full DNS propagation before deploying EKS cluster |

---

## ✅ Verify Your Setup

Before running Terraform, verify everything is configured correctly:

```bash
# 1. Check nameservers point to AWS Route53
dig NS happycuban-example.dk +short | grep awsdns

# Expected: Should return 4 AWS nameservers
# ns-XXXX.awsdns-XX.org.
# ns-XXXX.awsdns-XX.com.
# ns-XXX.awsdns-XX.net.
# ns-XXXX.awsdns-XX.co.uk.

# 2. Verify hosted zone exists in AWS
aws route53 list-hosted-zones --query "HostedZones[?Name=='happycuban-example.dk.']"

# Expected: Should return your hosted zone with ID

# 3. Test basic DNS resolution
nslookup happycuban-example.dk

# Expected: Should resolve (might point to nothing yet, that's OK)

# 4. Confirm hosted zone ID format is correct
echo "Z1234EXAMPLE5678" | grep -E '^Z[A-Z0-9]+$'

# Expected: No output means format is correct

# 5. Verify AWS CLI is using correct region
aws configure get region

# Expected: Should match your terraform.tfvars region
```

---

## 🚀 After EKS Deployment

Once your EKS cluster is deployed, ExternalDNS will automatically create DNS records:

```bash
# Check DNS records created by ExternalDNS
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234EXAMPLE5678 \
  --query "ResourceRecordSets[?Type=='A']"

# Expected records (created automatically):
# - argocd.happycuban-example.dk → Points to AWS Load Balancer
# - traefik.happycuban-example.dk → Points to AWS Load Balancer
# - *.happycuban-example.dk → Wildcard for all services
```

### Verify Service DNS

```bash
# Check if ArgoCD DNS is working
dig argocd.happycuban-example.dk +short

# Check if Traefik DNS is working
dig traefik.happycuban-example.dk +short

# Check wildcard
dig anything.happycuban-example.dk +short

# All should return the same AWS Load Balancer IP/hostname
```

### Verify SSL Certificates

```bash
# Check certificate status
kubectl get certificates -n traefik

# Expected output:
# NAME                    READY   SECRET                  AGE
# traefik-tls-cert       True    traefik-tls-secret      5m

# Check certificate details
kubectl describe certificate traefik-tls-cert -n traefik

# Verify via browser
# https://argocd.happycuban-example.dk (should show valid SSL)
```

---

## 🔧 Troubleshooting

### DNS Not Resolving After Deployment

```bash
# 1. Check if hosted zone exists
aws route53 list-hosted-zones --query "HostedZones[?Name=='happycuban-example.dk.']"

# 2. Check if ExternalDNS created records
aws route53 list-resource-record-sets --hosted-zone-id Z1234EXAMPLE5678

# 3. Check ExternalDNS logs
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns

# 4. Verify load balancer is healthy
kubectl get svc -n traefik
```

### Certificate Not Issuing

```bash
# 1. Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# 2. Check certificate status
kubectl describe certificate traefik-tls-cert -n traefik

# 3. Check challenge status
kubectl get challenges -A

# 4. Verify Route53 permissions
aws route53 list-resource-record-sets --hosted-zone-id Z1234EXAMPLE5678 \
  | grep _acme-challenge
```

### Nameserver Delegation Issues

```bash
# Check from multiple DNS servers
dig @8.8.8.8 NS happycuban-example.dk +short
dig @1.1.1.1 NS happycuban-example.dk +short
dig @208.67.222.222 NS happycuban-example.dk +short

# If results differ, DNS is still propagating - wait longer

# Check SOA record
dig SOA happycuban-example.dk +short

# Should show AWS nameserver as primary
```

---

## 📚 Additional Resources

### AWS Documentation
- [Route53 Developer Guide](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html)
- [Getting Started with Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html)
- [Registering Domain Names](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html)
- [Migrating DNS to Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html)
- [DNS Best Practices](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/best-practices-dns.html)
- [Route53 Pricing](https://aws.amazon.com/route53/pricing/)

### EKS & Kubernetes
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [ExternalDNS Documentation](https://kubernetes-sigs.github.io/external-dns/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

### DNS Tools
- [DNS Propagation Checker](https://www.whatsmydns.net/)
- [DNS Checker](https://dnschecker.org/)
- [MX Toolbox](https://mxtoolbox.com/SuperTool.aspx)
- [DNS Lookup Tool](https://www.nslookup.io/)

---

## 🎓 Understanding DNS Flow in This Setup

```
User Browser
     ↓
     ↓ (1) Looks up: argocd.happycuban-example.dk
     ↓
Domain Registrar Nameservers
     ↓
     ↓ (2) Delegates to Route53
     ↓
AWS Route53 Hosted Zone
     ↓
     ↓ (3) Returns: ALB hostname (a1b2c3.us-west-2.elb.amazonaws.com)
     ↓
Application Load Balancer
     ↓
     ↓ (4) Routes to Kubernetes Service
     ↓
Traefik Ingress Controller
     ↓
     ↓ (5) Routes to correct pod based on hostname
     ↓
ArgoCD Service Pod
```

**ExternalDNS Role**: Watches Kubernetes Ingress/Service resources and automatically creates/updates Route53 DNS records

**cert-manager Role**: Uses Route53 DNS validation to prove domain ownership and obtain Let's Encrypt certificates

---