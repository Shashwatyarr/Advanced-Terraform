# Multi-Environment AWS Infrastructure Provisioning using Terraform

## 1. Project Overview
This project provisions a multi-environment AWS infrastructure (Dev and Prod) using a single, reusable Terraform codebase. It leverages **Terraform Workspaces** and environment-specific `.tfvars` files to isolate state and dynamically inject configuration. The infrastructure comprises EC2 instances (Compute), S3 buckets (Storage), and Security Groups (Networking/Security), adhering to best practices like avoiding hardcoded IDs via AWS Data Blocks.

## 2. AWS Resources Used
- **Amazon EC2 (`aws_instance`)**: Scalable compute capacity (1x `t3.micro` for Dev, 3x `t3.small` for Prod).
- **Amazon S3 (`aws_s3_bucket`)**: Object storage with SSE encryption and Public Access Block enabled.
- **Amazon EC2 Security Group (`aws_security_group`)**: Network firewall restricting SSH access to a configurable CIDR.

## 3. Folder Structure
```text
terraform-multi-environment/
├── bootstrap/              # Sets up S3 backend & DynamoDB table for remote state
├── main.tf                 # Core infrastructure (EC2, S3, Security Groups)
├── variables.tf            # Input definitions with validation
├── locals.tf               # Environment configuration map and common tags
├── providers.tf            # Provider configuration and AWS Data Blocks
├── outputs.tf              # Resource IPs, IDs, and active environment
├── versions.tf             # Terraform & Provider version constraints
├── terraform.tfvars.dev    # Variables for the Dev environment
├── terraform.tfvars.prod   # Variables for the Prod environment
├── .gitignore              # Ignores sensitive data and state files
└── README.md               # Documentation and deployment workflow
```

## 4. Terraform Workspaces
Terraform Workspaces isolate the state files for different environments within the same working directory. The active workspace is accessible in code via `terraform.workspace`. This project uses `terraform.workspace` to dynamically lookup values from a map in `locals.tf`, ensuring safe environment isolation without code duplication.

## 5. Variables and `.tfvars`
Variables (`variables.tf`) declare the inputs the module accepts. `.tfvars` files (`terraform.tfvars.dev` and `terraform.tfvars.prod`) inject environment-specific values into these variables. For example, the `ssh_cidr` variable is open (`0.0.0.0/0`) in Dev but restricted (`10.0.0.0/8`) in Prod. Using `.tfvars` ensures that environment configurations are explicitly defined and separated from the underlying resource logic.

## 6. AWS Data Blocks
Data blocks dynamically discover existing AWS resources. This prevents hardcoding IDs that vary between regions or accounts. The project uses:
1. `aws_availability_zones`: Discovers available AZs in the region.
2. `aws_vpc` (default): Finds the default VPC.
3. `aws_subnets`: Finds subnets attached to the default VPC.
4. `aws_ami`: Finds the latest Ubuntu 22.04 LTS AMI.

## 7. Dev vs Prod Configuration
- **Dev Workspace (`dev`)**: Provisions **1** `t3.micro` instance. Uses `terraform.tfvars.dev` for relaxed SSH access and a `-dev` S3 bucket.
- **Prod Workspace (`prod`)**: Provisions **3** `t3.small` instances. Uses `terraform.tfvars.prod` for restricted SSH access and a `-prod` S3 bucket.
Both environments share the identical underlying resource declarations in `main.tf`.

## 8. Remote State and Scope
This project defaults to local state for ease of deployment during evaluations. However, a `bootstrap` directory is included to provision an S3 bucket and DynamoDB table to support **Remote State** and locking. 
* To use remote state, first `cd bootstrap`, run `terraform init && terraform apply`.
* Then, configure a `backend "s3" {}` block in the root `versions.tf` using the generated bucket and table names.

## 9. AWS Authentication
This project uses the AWS Terraform provider. Authentication is expected via standard environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), an AWS CLI profile (`aws configure`), or an IAM role attached to the executing environment. The provider automatically discovers these credentials; none are hardcoded in the Terraform files.

## 10. Deployment Workflow (Validation & Plan Verification)

### Step 1: Initialize
Initialize the working directory containing Terraform configuration files.
```bash
terraform init
```

### Step 2: Create Workspaces
Create the workspaces for `dev` and `prod`. (If they already exist, use `terraform workspace select <env>`).
```bash
terraform workspace new dev
terraform workspace new prod
```

### Step 3: Verify & Validate
Ensure the code is correctly formatted and syntactically valid.
```bash
terraform fmt
terraform validate
```

### Step 4: Deploy DEV
Select the dev workspace and apply using the dev tfvars.
```bash
terraform workspace select dev
terraform plan -var-file="terraform.tfvars.dev"
terraform apply -var-file="terraform.tfvars.dev"
```

### Step 5: Deploy PROD
Select the prod workspace and apply using the prod tfvars.
```bash
terraform workspace select prod
terraform plan -var-file="terraform.tfvars.prod"
terraform apply -var-file="terraform.tfvars.prod"
```

### Step 6: Verify Outputs
```bash
terraform workspace list
terraform output
```
Verify that `dev` created 1 instance, `prod` created 3 instances, and the outputs reflect the correct environment.

## 11. Cleanup Instructions
To safely tear down the infrastructure, ensure you are in the correct workspace and pass the corresponding `.tfvars` file. Do this for each environment to avoid unintended destruction.

**Destroy Dev:**
```bash
terraform workspace select dev
terraform destroy -var-file="terraform.tfvars.dev"
```

**Destroy Prod:**
```bash
terraform workspace select prod
terraform destroy -var-file="terraform.tfvars.prod"
```

---

## 12. MSE Viva Questions and Answers

**1. What is Terraform?**
Terraform is an open-source Infrastructure as Code (IaC) tool by HashiCorp that allows you to define, provision, and manage cloud infrastructure using a declarative configuration language (HCL).

**2. Why are Terraform Workspaces used?**
Workspaces allow you to manage multiple distinct states (e.g., dev, prod) from the same configuration directory. They enable reusing the same Terraform code across different environments safely.

**3. What is the difference between variables and locals?**
Variables are inputs passed into a Terraform module from the outside (e.g., via CLI or `.tfvars`). Locals are internal, derived values computed within the module to reduce repetition and complex expressions.

**4. Why do we use tfvars files?**
`.tfvars` files are used to assign environment-specific values to variables, keeping sensitive or environment-specific data out of the core resource configuration.

**5. What are Terraform Data Blocks?**
Data blocks (or Data Sources) allow Terraform to dynamically query and fetch information about infrastructure that exists outside of the current Terraform configuration, such as AMIs, VPCs, or Subnets.

**6. Why should AMI IDs not be hardcoded?**
AMI IDs are region-specific and periodically updated (e.g., for security patches). Hardcoding them makes the code brittle, difficult to maintain, and non-portable across regions.

**7. How does the same code provision dev and prod?**
The code dynamically references variables and local mappings. By switching the active workspace (`terraform.workspace`) and passing different `.tfvars` files, the same code adapts its resource definitions based on the active environment.

**8. Why does prod have 3 EC2 instances?**
In `locals.tf` (and `terraform.tfvars.prod`), the `instance_count` variable/map for `prod` is set to 3. The `count` meta-argument on the `aws_instance` resource loops 3 times, provisioning three identical instances for higher availability.

**9. What is the purpose of resource tags?**
Tags are key-value pairs assigned to cloud resources for organization, cost tracking, security auditing, and automation. In this project, they indicate which environment a resource belongs to.

**10. What happens when we switch workspaces?**
Switching workspaces points Terraform to a different, isolated state file. Any `terraform apply` or `destroy` will only affect the infrastructure tracked in that specific workspace's state file.

**11. How does Terraform track infrastructure state?**
Terraform tracks the mapping between the configuration code and the real-world cloud resources in a JSON state file (`terraform.tfstate`). It uses this file to determine what needs to be created, updated, or destroyed.

**12. Why should `terraform.tfstate` not be committed to Git?**
The state file can contain sensitive information (secrets, passwords, database URLs) in plain text. Committing it exposes this data and can cause conflicts if multiple people try to update the infrastructure simultaneously.

**13. What is the purpose of `terraform validate`?**
It checks the syntax, configuration consistency, and structural validity of the Terraform files without accessing remote state or APIs.

**14. What happens if `terraform apply` fails?**
Terraform updates the state file with whatever resources were successfully created before the failure. On the next run, it will attempt to pick up where it left off to resolve the discrepancies.

**15. What is the difference between local and remote state?**
Local state stores the `.tfstate` file on your local machine, which is risky for teams. Remote state stores the state file in a remote backend (like S3 or Terraform Cloud), enabling state locking and team collaboration.
