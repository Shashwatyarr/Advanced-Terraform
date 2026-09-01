# 2-Tier Architecture - Web Application with RDS Database

This Terraform project demonstrates a production-ready 2-tier architecture for web applications. It deploys a web server in a public subnet and a relational database in private subnets, following AWS best practices for security and scalability.

## 🎯 Architecture Overview

```
Internet Gateway
        ↓
    [Public Subnet]
  ┌───────────────┐
  │  EC2 Web      │ (t2.micro - Application Server)
  │  Server       │ 
  └───────────────┘
        ↓
  [Security Group]
        ↓
┌──────────────────┐
│  RDS Database    │ (db.t3.micro - MySQL)
│  (Private)       │
│  Multi-AZ        │
└──────────────────┘
```

## 🗂️ Project Structure

```
2-Tier Architecture/
├── main.tf                      # Root module orchestration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── terraform.tfvars.example     # Example values file
├── README.md                    # This file
└── modules/
    ├── vpc/                     # VPC and subnet configuration
    ├── security_groups/         # Security group rules
    ├── ec2/                     # Web server configuration
    ├── rds/                     # Database configuration
    └── secrets/                 # Secrets Manager setup
```

## 📋 Key Components

### 1. **VPC Module**
Sets up a custom Virtual Private Cloud with:
- Single VPC with configurable CIDR block (default: 10.0.0.0/16)
- 1 Public subnet for web servers
- 2 Private subnets for RDS database (required for Multi-AZ)
- Internet Gateway for public internet access
- NAT Gateway for private subnet outbound connectivity
- Route tables for routing traffic

**Why**: Provides network isolation and security through subnet segmentation

### 2. **Security Groups Module**
Creates firewall rules:
- **Web Tier Security Group**:
  - Inbound: HTTP (80), HTTPS (443), SSH (22)
  - Outbound: All traffic allowed
  
- **Database Tier Security Group**:
  - Inbound: MySQL (3306) only from web tier SG
  - Outbound: Restricted to necessary services

**Why**: Implements least privilege principle - only allow required traffic

### 3. **EC2 Module**
Provisions the application server:
- Instance Type: t2.micro (free tier eligible)
- Placement: Public subnet
- Public IP: Automatically assigned
- Root Volume: 20GB gp2

**Why**: Hosts the web application accessible from internet

### 4. **RDS Module**
Deploys managed relational database:
- Engine: MySQL 8.0
- Instance Class: db.t3.micro
- Storage: 10GB (configurable)
- Multi-AZ: Enabled for high availability
- Backup: 7-day retention
- Encryption: Enabled (at rest)

**Why**: Managed database service with automatic backups and failover

### 5. **Secrets Module**
Secures sensitive credentials:
- Database password generation (random, 16 characters)
- Storage in AWS Secrets Manager
- No passwords in Terraform files
- Easy rotation capability

**Why**: Security best practice - never commit secrets to version control

## 🚀 Getting Started

### Prerequisites

```bash
# Check versions
terraform --version  # >= 1.0
aws --version       # Latest
```

### Configuration

1. **Copy and customize variables**:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

2. **Key variables to customize**:
   - `project_name`: Your project name
   - `environment`: dev, staging, or prod
   - `aws_region`: AWS region to deploy
   - `vpc_cidr`: VPC CIDR block
   - `public_subnet_cidr`: Public subnet CIDR
   - `private_subnet_cidrs`: Private subnet CIDRs (list of 2)
   - `ec2_instance_type`: EC2 instance size
   - `db_instance_class`: RDS instance class
   - `db_allocated_storage`: Database storage in GB

### Deployment

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan -out=tfplan

# Deploy infrastructure
terraform apply tfplan

# Retrieve outputs
terraform output
terraform output web_server_public_ip
terraform output application_url
terraform output rds_endpoint
```

## 📊 Outputs

The project provides these outputs:

```
vpc_id                 - VPC identifier
web_server_public_ip   - Public IP of EC2 instance
web_server_public_dns  - Public DNS name
application_url        - Complete HTTP URL to application
rds_endpoint           - Database connection endpoint
rds_port               - Database port (3306)
database_name          - Database name
```

## 🔐 Security Features

✅ **Network Security**
- Subnets segregated by tier (public/private)
- Security groups enforce least privilege
- NAT Gateway for private outbound traffic

✅ **Database Security**
- Multi-AZ deployment for high availability
- Encryption at rest enabled
- Regular automated backups (7 days)
- Managed by AWS (no OS patching needed)

✅ **Credential Management**
- Passwords generated securely (random, 16+ chars)
- Stored in AWS Secrets Manager
- Never exposed in code or logs
- Easy rotation via Secrets Manager

✅ **Access Control**
- Database accessible only from web tier
- Web server publicly accessible (customizable)
- SSH access for management

## 🔌 Connectivity Details

### Web Tier (Public)
- **Accessibility**: Publicly accessible via Internet Gateway
- **Purpose**: Host web application/API
- **Communication**: HTTP/HTTPS to end users, SQL queries to RDS

### Database Tier (Private)
- **Accessibility**: Only from Web tier via Security Group
- **Purpose**: Store application data
- **Communication**: Receives SQL queries from EC2 instance
- **No Direct Internet**: Outbound through NAT Gateway only

## 🛠️ Common Workflows

### Modify Database Size
```bash
# Edit terraform.tfvars
db_allocated_storage = 20
db_instance_class = "db.t3.small"

# Apply changes
terraform apply
```

### Scale Web Server
```bash
# Change instance type
ec2_instance_type = "t3.small"

# Note: This will terminate the current instance
terraform apply
```

### Add Database Credentials to Application
```bash
# Retrieve password from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id day22-rds-demo-db-password \
  --query SecretString --output text
```

## 📈 High Availability & Disaster Recovery

| Feature | Implementation |
|---------|-----------------|
| **Database HA** | Multi-AZ RDS with automatic failover |
| **Backups** | Automated 7-day retention |
| **Encryption** | At-rest encryption enabled |
| **Monitoring** | CloudWatch metrics available |
| **Snapshots** | Can be created manually or via snapshots |

## 💰 Cost Estimation

| Component | Estimated Monthly Cost (Free Tier) |
|-----------|-----------------------------------|
| VPC + NAT | ~$32 (NAT Gateway) |
| EC2 (t2.micro) | Free (eligible) |
| RDS (db.t3.micro) | Free (eligible) |
| Secrets Manager | Free (first 30 secrets) |
| **Total** | **~$32-40/month** |

*Note: Costs vary by region. Use [AWS Calculator](https://calculator.aws/) for exact estimates.*

## 🧹 Cleanup

Remove all resources to avoid charges:

```bash
# Destroy all infrastructure
terraform destroy

# Confirm when prompted
# This will:
# - Terminate EC2 instance
# - Delete RDS database
# - Remove VPC and subnets
# - Clean up security groups
# - Remove Secrets Manager secrets (if configured)
```

## 🐛 Troubleshooting

### **Connection Timeout to RDS**
```
Issue: Cannot connect to database from EC2
Fix: Verify security group rules allow port 3306 between tiers
```

### **EC2 Instance Not Accessible**
```
Issue: SSH connection refused
Fix: Check security group allows port 22 inbound
Fix: Verify public IP assignment and route table
```

### **Secrets Manager Permission Denied**
```
Issue: Cannot retrieve database password
Fix: Ensure IAM role on EC2 has SecretsManager read permissions
```

### **Terraform State Lock**
```
Issue: "Error acquiring the lock"
Fix: No concurrent Terraform operations
Fix: Remove lock file: rm .terraform.terraform.lock.hcl
```

## 📚 Learn More

- [AWS 2-Tier Architecture Patterns](https://aws.amazon.com/architecture/reference-architectures/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [VPC Security Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Security.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## ⚠️ Important Notes

- Database backups: 7-day retention configured
- EC2 root volume: 20GB default (adjust if needed)
- SSH key pair: Create one before deployment or use Systems Manager Session Manager
- DNS records: Use RDS endpoint for internal connections
- Database replication: Multi-AZ provides automatic standby

## 🎓 What You'll Learn

✅ Multi-tier architecture design patterns
✅ Network segmentation with VPC and subnets
✅ Security group rules and least privilege
✅ Terraform modules for code organization
✅ RDS configuration and management
✅ Secrets management best practices
✅ Public/private subnet routing
✅ AWS managed services benefits

---

**Last Updated**: 2026-09-02
**Terraform Version**: >= 1.0
**AWS Provider Version**: ~> 5.0
