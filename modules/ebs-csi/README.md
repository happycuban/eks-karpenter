# EBS CSI Module

This module deploys the Amazon EBS CSI driver with Pod Identity authentication for secure, encrypted block storage in EKS.

## Features

- **EBS CSI Driver**: Version 1.51.1-eksbuild.1 for reliable block storage
- **Pod Identity**: Modern authentication replacing IRSA
- **KMS Encryption**: Customer-managed keys for data-at-rest encryption
- **Storage Classes**: Pre-configured GP3 storage classes with encryption
- **IAM Integration**: Automated IAM roles and policies for secure access

## Key Components

- AWS EBS CSI Driver Helm chart
- Pod Identity associations for secure AWS API access
- IAM roles with minimal required permissions
- Encrypted GP3 storage classes
- KMS key integration for encryption

## Storage Classes Created

- `gp3-encrypted`: GP3 volumes with KMS encryption
- `gp3-encrypted-retain`: GP3 volumes with retain policy

## Usage

```hcl
module "ebs_csi" {
  source = "../../modules/ebs-csi"
  
  cluster_name = "my-cluster"
  kms_key_arn  = module.kms.key_arn
  env          = "dev"
}
```

## Variables

- `cluster_name`: Name of the EKS cluster
- `kms_key_arn`: ARN of KMS key for encryption
- `env`: Environment name (dev/tes/sta/pro)

## Outputs

- `ebs_csi_driver_role_arn`: ARN of the IAM role for EBS CSI driver
- `pod_identity_association_arn`: ARN of the Pod Identity association