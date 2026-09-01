# AWS Policy and Governance

This Terraform project demonstrates how to implement **AWS Policy Creation** and **Governance Setup** using Terraform. It showcases best practices for cloud security, compliance monitoring, and automated policy enforcement.

## 🎯 Project Objectives

1. **Policy Creation**: Implement IAM policies to enforce security best practices
2. **Governance Setup**: Configure AWS Config for continuous compliance monitoring
3. **Resource Tagging**: Demonstrate tagging strategies for resource management
4. **S3 Security**: Apply encryption, versioning, and access controls
5. **Compliance Monitoring**: Track configuration changes and detect violations

## 📁 Project Structure

```
Policy and governance/
├── provider.tf       # AWS provider configuration
├── variables.tf      # Input variables
├── main.tf          # S3 bucket and shared resources
├── iam.tf           # IAM policies and roles
├── config.tf        # AWS Config recorder and rules
├── outputs.tf       # Output values
└── README.md        # This file
```

## 🔐 IAM Policies Created

### 1. MFA Delete Policy
Denies S3 object deletion unless Multi-Factor Authentication is present.
- **Use Case**: Protect against accidental/malicious data deletion
- **Enforcement**: Requires MFA token for all S3 delete operations

### 2. S3 Encryption in Transit Policy
Requires HTTPS/TLS for all S3 operations.
- **Use Case**: Prevent data interception during transmission
- **Enforcement**: Denies any S3 operation without aws:SecureTransport flag

### 3. Required Tags Policy
Enforces tagging standards for EC2 instances and other resources.
- **Use Case**: Cost allocation and resource management
- **Enforcement**: Requires Environment and Owner tags on EC2 instances

### 4. Demo IAM User
Sample user with attached policies for demonstration purposes.
- Created in `/governance/` path
- Useful for testing policy restrictions

## 🛡️ AWS Config Rules

This project configures multiple compliance rules:

1. **S3 Public Write Prohibited** - Prevents public write access to S3 buckets
2. **S3 Encryption Enabled** - Ensures server-side encryption on S3 buckets
3. **S3 Public Read Prohibited** - Blocks public read access to S3 buckets
4. **EBS Volumes Encrypted** - Verifies all EBS volumes are encrypted
5. **Required Tags** - Checks for Environment and Owner tags
6. **IAM Password Policy** - Enforces strong password requirements
7. **Root MFA Enabled** - Ensures root account has MFA configured

## 🚀 Quick Start

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply configuration
terraform apply

# View outputs
terraform output
```

## 📊 Key Outputs

- `config_bucket_name`: S3 bucket for AWS Config data
- `config_recorder_name`: AWS Config recorder instance
- `mfa_delete_policy_arn`: ARN of MFA delete policy
- `s3_encryption_transit_policy_arn`: ARN of S3 encryption policy
- `require_tags_policy_arn`: ARN of tag enforcement policy
- `demo_user_name`: Demo IAM user for testing

## 🔐 Security Features

✅ Encryption at rest for S3 (AES256)
✅ Encryption in transit (HTTPS/TLS enforcement)
✅ MFA requirement for critical operations
✅ Public access blocking on S3 buckets
✅ Mandatory resource tagging
✅ AWS Config compliance monitoring
✅ Versioning enabled on critical data

## 📚 Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `aws_region` | AWS region | us-east-1 | string |
| `project_name` | Project name prefix | terraform-governance-demo | string |

## 🧹 Cleanup

```bash
terraform destroy
```

## 📖 Additional Resources

- [AWS Config Documentation](https://docs.aws.amazon.com/config/)
- [IAM Policy Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🚀 Usage

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- AWS account with permissions to create IAM roles, policies, Config, and S3 resources

### Deployment Steps

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Review the Plan**
   ```bash
   terraform plan
   ```

3. **Apply the Configuration**
   ```bash
   terraform apply
   ```

4. **View Outputs**
   ```bash
   terraform output
   ```

### Customize Variables

You can override default values:

```bash
terraform apply -var="aws_region=us-west-2" -var="project_name=my-governance"
```

## 📊 Monitoring Compliance

After deployment, you can monitor compliance through:

1. **AWS Console**: Navigate to AWS Config → Rules
2. **AWS CLI**: 
   ```bash
   aws configservice describe-compliance-by-config-rule
   ```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: The S3 bucket will be force-destroyed, including all stored Config snapshots.

## 🏗️ Architecture

```
┌─────────────────┐
│   IAM Policies  │
│  - MFA Delete   │
│  - Encryption   │
│  - Tagging      │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│    AWS Config Service       │
│  - Recorder (Started)       │
│  - Delivery Channel         │
│  - 7 Config Rules           │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│    S3 Bucket (Encrypted)    │
│  - Versioning Enabled       │
│  - Public Access Blocked    │
│  - Secure Transport Only    │
└─────────────────────────────┘
```

## 💡 Key Learning Points

1. **Policy as Code**: IAM policies defined in Terraform are version-controlled and repeatable
2. **Continuous Compliance**: AWS Config continuously monitors resources against rules
3. **Defense in Depth**: Multiple layers of security (IAM, S3 policies, encryption)
4. **Automated Governance**: No manual intervention needed for compliance checks
5. **Tagging Strategy**: Consistent tagging enables cost tracking and resource management

## 📝 Best Practices Implemented

- ✅ Least privilege access with IAM policies
- ✅ Encryption at rest and in transit
- ✅ S3 bucket versioning for audit trail
- ✅ Public access blocking on sensitive buckets
- ✅ Resource tagging for governance
- ✅ Continuous configuration monitoring
- ✅ Automated compliance reporting

## 🔗 Resources

- [AWS Config Documentation](https://docs.aws.amazon.com/config/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Config Rules](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html)


