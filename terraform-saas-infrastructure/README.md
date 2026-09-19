# Multi-Environment Provisioning of a Scalable SaaS Application on AWS

## 1. Project Overview
This project provisions a highly available, scalable, and secure infrastructure for a SaaS application on AWS. It uses Terraform to define the infrastructure as code (IaC). The codebase is designed to be completely reusable across multiple environments (`dev`, `test`, `prod`) without duplicating code, utilizing Terraform Workspaces and environment-specific variable files.

## 2. Architecture
The infrastructure is instantiated independently for each environment and follows AWS best practices:

*   **Public Layer**: Internet Gateway, Application Load Balancer (ALB), NAT Gateways.
*   **Application Layer**: Auto Scaling Group of EC2 instances spanning multiple Availability Zones in private subnets.
*   **Data Layer**: Amazon RDS PostgreSQL instance in private subnets, Amazon S3 for static assets.
*   **Management Layer**: AWS Secrets Manager for DB credentials, IAM Roles for secure access, CloudWatch for monitoring and alerting.

## 3. AWS Services Used
*   **Amazon VPC**: Custom network isolation.
*   **Amazon EC2 / Auto Scaling**: Elastic compute capacity.
*   **Application Load Balancer (ALB)**: Traffic distribution.
*   **Amazon RDS**: Managed relational database.
*   **Amazon S3**: Object storage and remote Terraform state.
*   **Amazon DynamoDB**: State locking mechanism.
*   **AWS IAM**: Principle of least privilege access.
*   **AWS Secrets Manager**: Secure credential storage.
*   **Amazon CloudWatch**: Metrics and SNS alarms.

## 4. Folder Structure
```text
terraform-saas-infrastructure/
│
├── main.tf                 # Root module orchestrating child modules
├── providers.tf            # AWS provider and default tags
├── backend.tf              # S3 Remote State configuration
├── versions.tf             # Terraform constraints
├── variables.tf            # Input definitions
├── locals.tf               # Local variables (environment mapping)
├── outputs.tf              # Outputs (URLs, Endpoints)
├── dev.tfvars              # Configuration for DEV
├── test.tfvars             # Configuration for TEST
├── prod.tfvars             # Configuration for PROD
├── .gitignore              # Ignores state and secrets
├── README.md               # This document
│
├── bootstrap/              # Standalone config for S3 Backend setup
│
└── modules/                # Reusable domain-specific components
    ├── vpc/
    ├── security_groups/
    ├── iam/
    ├── alb/
    ├── autoscaling/
    ├── rds/
    ├── s3/
    └── cloudwatch/
```

## 5. Terraform Modules
To avoid a monolithic codebase, the infrastructure is decomposed into custom, reusable modules. A module (like `vpc`) does not know whether it is in "dev" or "prod". It simply accepts input variables (like CIDR blocks) and provisions the resources. The root `main.tf` passes the correct variables to the modules based on the active environment.

## 6. Workspace Concept
Terraform Workspaces allow you to manage multiple states using the same configuration files. When you run `terraform workspace select dev`, Terraform automatically points to the `env:/dev/` directory inside your S3 backend bucket. This ensures complete logical isolation of state files.

## 7. Environment Configuration
Instead of complex `if/else` logic in the code, environment differences are handled using `.tfvars` files:
*   **`dev.tfvars`**: Single NAT Gateway, small EC2/RDS instances, relaxed alarms, Single-AZ.
*   **`prod.tfvars`**: Multiple NAT Gateways, large EC2/RDS instances, strict alarms, Multi-AZ failover.

## 8. Remote State Architecture
State files are stored in an encrypted **Amazon S3** bucket to prevent sensitive data from leaking into Git. An **Amazon DynamoDB** table is used for state locking, meaning if two developers run `terraform apply` simultaneously, one will safely wait, preventing state corruption.

## 9. Backend Bootstrap
Terraform has a chicken-and-egg problem: it cannot store its state in an S3 bucket that it hasn't created yet. Therefore, the `bootstrap/` directory is run *locally* one time to create the S3 bucket and DynamoDB table. After that, the main project uses those resources for remote state.

---

## 10. Installation Prerequisites
1.  [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (>= 1.5.0) installed.
2.  [AWS CLI](https://aws.amazon.com/cli/) installed.
3.  An active AWS Account.

## 11. AWS Authentication
Configure your AWS CLI with an IAM user that has AdministratorAccess (or sufficient permissions):
```bash
aws configure
```

## 12. Backend Bootstrap Workflow
First, we must create the remote state infrastructure.
```bash
cd bootstrap
terraform init
terraform apply -auto-approve
```
**CRITICAL:** Take note of the `s3_bucket_name` output. Open `backend.tf` in the root directory and replace `"REPLACE_WITH_YOUR_BACKEND_BUCKET_NAME"` with this exact bucket name.

## 13. Terraform Initialization
Navigate back to the root directory and initialize the remote backend.
```bash
cd ..
terraform init
```

## 14. Creating Workspaces
Create the logical environments.
```bash
terraform workspace new dev
terraform workspace new test
terraform workspace new prod
```

## 15. Deploying DEV
```bash
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

## 16. Deploying TEST
```bash
terraform workspace select test
terraform plan -var-file="test.tfvars"
terraform apply -var-file="test.tfvars"
```

## 17. Deploying PROD
```bash
terraform workspace select prod
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## 18. Destroying Environments
To avoid incurring AWS charges, destroy the environments when you are done.
```bash
# Destroy DEV
terraform workspace select dev
terraform destroy -var-file="dev.tfvars"

# Destroy TEST
terraform workspace select test
terraform destroy -var-file="test.tfvars"

# Destroy PROD (Requires disabling deletion protection manually in AWS Console for RDS, then running destroy)
terraform workspace select prod
terraform destroy -var-file="prod.tfvars"
```

---

## 19. Security Considerations
*   **Network Isolation:** EC2 and RDS are deployed in private subnets with no public IPs.
*   **Least Privilege:** Security Groups ensure the DB only talks to the App, and the App only talks to the ALB. IAM Instance Profiles eliminate hardcoded AWS keys.
*   **Secret Management:** DB passwords are auto-generated and stored strictly in AWS Secrets Manager.
*   **State Security:** `.tfstate` files are excluded from Git via `.gitignore` and are encrypted at rest in S3.

## 20. Troubleshooting
*   **Error: Bucket does not exist during `init`**: You forgot to run the bootstrap step or didn't update `backend.tf` with the correct bucket name.
*   **Error: RDS deletion protection**: By design, PROD RDS cannot be destroyed by Terraform. You must log into the AWS Console, modify the DB to disable deletion protection, and run destroy again.
*   **Error: State lock held**: If a previous apply crashed, the DynamoDB lock might be stuck. Use `terraform force-unlock <LOCK_ID>`.

---

## 21. MSE Viva Explanation Guide

If you are asked these questions during your viva, here is how you answer them:

*   **Why Terraform?** It is cloud-agnostic, uses a declarative syntax (HCL), and manages state, allowing us to plan changes before applying them and treating infrastructure as standard software code.
*   **Why Workspaces?** They allow us to use a single set of configuration files to manage multiple distinct environments (Dev/Test/Prod). Terraform natively separates the state files under the hood (`env:/dev/`, `env:/prod/`).
*   **Why custom modules?** To keep the code DRY (Don't Repeat Yourself). Instead of writing VPC logic three times, we write it once in a module and instantiate it three times with different variables. It also abstracts complexity away from the root `main.tf`.
*   **Why remote state?** Local state files (`terraform.tfstate`) make team collaboration impossible and expose sensitive data (like DB passwords) if pushed to GitHub. Remote S3 state is secure, centralized, and versioned.
*   **Why state locking?** If Developer A and Developer B both run `terraform apply` at the exact same time, they could corrupt the infrastructure. DynamoDB locking prevents concurrent executions.
*   **Why separate environments?** Standard software development lifecycle (SDLC). You need a sandbox (Dev) to write code, a staging area (Test) to run QA, and a highly available live environment (Prod) for customers.
*   **How is environment configuration selected?** The workspace handles the state isolation, while the `.tfvars` files handle the business logic (e.g., `prod.tfvars` tells the modules to provision Multi-AZ RDS and larger EC2 instances).
*   **How does Auto Scaling differ between environments?** Dev uses `t3.micro` instances with a min/max of 1/2. Prod uses `t3.large` instances with a min/max of 2/5 to ensure high availability and handle production traffic spikes.
*   **How does Terraform prevent configuration drift?** When you run `terraform plan`, Terraform queries the AWS APIs to check the real-world status of the resources and compares it against the local code and the state file. If someone manually changed a security group in the AWS Console, Terraform will detect it and change it back to match the code.
*   **What happens if two developers run Terraform simultaneously?** The DynamoDB table holds a lock. The first developer gets the lock. The second developer's terminal will throw an error saying the state is locked and they must wait.
*   **What happens if `terraform apply` fails halfway?** Terraform updates the remote state file with exactly what it managed to build up to the point of failure. When you fix the error and run `apply` again, it resumes exactly where it left off.
*   **Why should `terraform.tfstate` not be stored in Git?** State files store sensitive infrastructure data in plain text. If you create an RDS database, the master password will be visible in the state file. Pushing this to a Git repository is a critical security breach.
