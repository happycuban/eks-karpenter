# EFS CSI Module

This module provisions an AWS EFS (Elastic File System) with the EFS CSI driver for EKS, using Pod Identity for authentication and optional KMS encryption.

## Features

- 🔐 **Pod Identity Authentication** - Modern EKS authentication using Pod Identity
- 🔒 **KMS Encryption** - Optional customer-managed KMS key encryption
- 🌐 **Multi-AZ Support** - Mount targets across multiple availability zones
- 📁 **Access Points** - Optional EFS access points for fine-grained permissions
- 📊 **Performance Options** - Configurable performance and throughput modes
- 🏷️ **Storage Classes** - Automatic creation of Kubernetes storage classes

## Usage

### Basic Usage

```hcl
module "efs_csi" {
  source = "./modules/efs-csi"

  region       = "eu-west-1"
  env          = "dev"
  cluster_name = "my-eks-cluster"
  
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
}
```

### Advanced Usage with KMS and Access Points

```hcl
module "efs_csi" {
  source = "./modules/efs-csi"

  region       = "eu-west-1"
  env          = "dev"
  cluster_name = "my-eks-cluster"
  
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345678", "subnet-87654321"]
  efs_csi_kms  = "arn:aws:kms:eu-west-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 100

  access_points = [
    {
      name = "app-data"
      path = "/app-data"
      creation_info = {
        owner_gid   = 1001
        owner_uid   = 1001
        permissions = "755"
      }
      posix_user = {
        gid = 1001
        uid = 1001
      }
    }
  ]

  tags = {
    Project = "MyApp"
    Team    = "DevOps"
  }
}
```

## Example Kubernetes Usage

### Using Dynamic Provisioning (Default Storage Class)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-default
  resources:
    requests:
      storage: 5Gi
```

### Using Access Points

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-ap-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-default-ap
  resources:
    requests:
      storage: 5Gi
```

### Multi-Pod Shared Storage Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shared-storage-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shared-storage-app
  template:
    metadata:
      labels:
        app: shared-storage-app
    spec:
      containers:
      - name: app
        image: nginx:latest
        volumeMounts:
        - name: shared-data
          mountPath: /shared-data
      volumes:
      - name: shared-data
        persistentVolumeClaim:
          claimName: efs-pvc
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | AWS region where the EFS file system will be created | `string` | n/a | yes |
| env | Environment for the EFS CSI driver (dev/tes/sta/pro) | `string` | n/a | yes |
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| vpc_id | VPC ID where the EFS file system will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for EFS mount targets | `list(string)` | n/a | yes |
| efs_csi_kms | KMS key ARN for EFS encryption | `string` | `null` | no |
| performance_mode | Performance mode for EFS (generalPurpose or maxIO) | `string` | `"generalPurpose"` | no |
| throughput_mode | Throughput mode for EFS (bursting or provisioned) | `string` | `"bursting"` | no |
| provisioned_throughput_in_mibps | Provisioned throughput in MiB/s | `number` | `null` | no |
| create_default_storage_class | Whether to create a default EFS storage class | `bool` | `true` | no |
| storage_class_name | Name for the EFS storage class | `string` | `"efs-default"` | no |
| access_points | List of EFS access points to create | `list(object)` | `[]` | no |
| tags | Additional tags to apply to EFS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| efs_csi_role_arn | ARN of the EFS CSI pod identity IAM role |
| efs_file_system_id | ID of the EFS file system |
| efs_file_system_dns_name | DNS name of the EFS file system |
| efs_mount_target_ids | List of EFS mount target IDs |
| efs_access_point_ids | List of EFS access point IDs |
| storage_class_name | Name of the created EFS storage class |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | >= 5.70.0 |
| kubectl | >= 1.14.0 |

## Key Differences from EBS

- **Multi-attach**: EFS supports ReadWriteMany (multiple pods can read/write simultaneously)
- **Performance**: EFS has different performance characteristics compared to EBS
- **Use Cases**: Better for shared application data, content management, and multi-pod scenarios
- **Cost**: Pay for actual storage used, not provisioned capacity
- **Availability**: Built-in multi-AZ redundancy

## Notes

- EFS mount targets are created in each provided subnet for high availability
- The security group allows NFS traffic (port 2049) from the VPC CIDR
- Access points provide fine-grained access control and POSIX permissions
- The module creates both dynamic provisioning and access point-based storage classes
- KMS encryption is optional but recommended for production workloads