# Application-Level Security Configuration

This configuration provides granular security control over different types of applications using Traefik middlewares.

## 🔒 Security Model

### **Admin Applications (IP Restricted)**
- **ArgoCD Dashboard**: `example-argocd.happycuban-example.dk`
- **Traefik Dashboard**: `traefik.happycuban-example.dk`
- **Lens/Monitoring**: Any app using `admin-ip-whitelist` middleware

**Access**: Only `192.0.2.244/32`

### **Public Applications (Open Access)**
- **User-facing apps**: Any app without the `admin-ip-whitelist` middleware
- **API endpoints**: Public services
- **Web applications**: Customer-facing services

**Access**: `0.0.0.0/0` (All IPs)

## 🚀 Usage

### **To Restrict an Application (Admin Only):**

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-admin-app
  namespace: my-namespace
spec:
  entryPoints:
    - web
    - websecure
  routes:
    - match: Host(`my-admin-app.happycuban-example.dk`)
      kind: Rule
      middlewares:
        - name: admin-ip-whitelist    # 👈 Add this middleware
          namespace: kube-system      # 👈 Reference kube-system namespace
      services:
        - name: my-admin-service
          port: 80
```

### **To Keep an Application Public:**

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: my-public-app
  namespace: my-namespace
spec:
  entryPoints:
    - web
    - websecure
  routes:
    - match: Host(`my-public-app.happycuban-example.dk`)
      kind: Rule
      # 👈 No admin-ip-whitelist middleware = public access
      services:
        - name: my-public-service
          port: 80
```

## 🔧 Configuration

### **Allowed IPs**
Managed via Terraform variable in `/environments/dev/variables.tf`:

```hcl
variable "allowed_ips" {
  type        = list(string)
  description = "List of IP addresses/CIDR blocks allowed to access admin resources"
  default     = ["192.0.2.244/32"]
}
```

### **Adding More IPs**
To allow additional IPs for admin access:

```hcl
allowed_ips = [
  "192.0.2.244/32",  # Your IP
  "1.2.3.4/32",         # Additional IP
  "10.0.1.0/24"         # Entire subnet
]
```

## 🎯 Benefits

1. **Granular Control**: Choose per-application which should be restricted
2. **Flexible**: Easy to add/remove restrictions per app
3. **Maintainable**: No complex load balancer configurations
4. **Scalable**: Single load balancer handles all traffic
5. **Cost-Effective**: No additional AWS load balancer costs

## 📝 Examples

### **Monitoring Stack (Admin Only)**
```yaml
# Prometheus UI - Admin only
middlewares:
  - name: admin-ip-whitelist
    namespace: kube-system

# Grafana Dashboards - Admin only  
middlewares:
  - name: admin-ip-whitelist
    namespace: kube-system
```

### **Application APIs (Public)**
```yaml
# User API - Public access
# No admin-ip-whitelist middleware

# Customer Portal - Public access
# No admin-ip-whitelist middleware
```

This approach gives you the perfect balance of security and usability! 🎯