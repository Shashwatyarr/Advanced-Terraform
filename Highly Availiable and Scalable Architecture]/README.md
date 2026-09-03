# Highly Available and Scalable AWS Architecture

This Terraform project provisions a highly available application stack in AWS. It runs application instances across private subnets in two Availability Zones and exposes them through a public Application Load Balancer.

## Architecture Diagram

![Highly available AWS architecture diagram](Screenshot%202026-09-03%20211357.png)

## Architecture Overview

- A VPC using the `10.0.0.0/16` CIDR block.
- Two public subnets, one in each Availability Zone, containing the Application Load Balancer and NAT gateways.
- Two private subnets, one in each Availability Zone, containing the Auto Scaling Group instances.
- One NAT gateway and Elastic IP per Availability Zone so private instances can reach the internet without being publicly addressable.
- An internet-facing Application Load Balancer listening on HTTP port 80 and HTTPS port 443.
- An HTTP target group forwarding traffic to port 80 on the application instances.
- An Auto Scaling Group with a default desired capacity of 2, a minimum of 1, and a maximum of 5 instances.
- CloudWatch CPU alarms and target tracking scaling at 70% average CPU utilization.
- A private, versioned, AES256-encrypted S3 bucket with public access blocked.

### Request Flow

1. A user sends HTTP or HTTPS traffic to the public Application Load Balancer.
2. The load balancer forwards healthy requests to EC2 instances in the private subnets.
3. Each instance runs the Django application in Docker. Host port 80 maps to container port 8000.
4. Outbound traffic from private instances uses the NAT gateway in the same Availability Zone.
5. The Auto Scaling Group replaces unhealthy instances and scales based on CPU utilization.

## Project Structure

| File | Purpose |
| --- | --- |
| `main.tf` | Terraform and AWS provider requirements and default tags |
| `vpc.tf` | VPC, subnets, route tables, internet gateway, NAT gateways, and Elastic IPs |
| `alb.tf` | Application Load Balancer, target group, and listener |
| `asg.tf` | Launch template, Auto Scaling Group, scaling policies, and CloudWatch alarms |
| `security_groups.tf` | Load balancer, application, and SSH security groups |
| `s3.tf` | Versioned and encrypted S3 bucket with public access blocked |
| `variables.tf` | Configurable deployment values and defaults |
| `outputs.tf` | VPC, subnet, load balancer, S3, ASG, and NAT gateway outputs |
| `scripts/user_data.sh` | Installs Docker and starts the Django application container |

## Prerequisites

- Terraform 1.0 or newer
- AWS CLI configured with credentials that can create the required VPC, EC2, ELB, Auto Scaling, CloudWatch, S3, and IAM-related resources
- An AWS region that contains the AMI configured in `ami_id`
- A default VPC quota that allows two Availability Zones, two NAT gateways, and the required public IPs

Verify the local tools:

```bash
terraform --version
aws sts get-caller-identity
```

## Deploy

Run Terraform from this directory because it is an independent root module:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

After deployment, display the important endpoints and resource identifiers:

```bash
terraform output
terraform output -raw load_balancer_dns
```

Open the load balancer DNS name in a browser after the target instances pass their health checks.

## Configuration

Override defaults with a `terraform.tfvars` file or command-line variables. Common settings include:

```hcl
region          = "us-east-1"
environment     = "production"
instance_type   = "t3.micro"
desired_capacity = 2
min_size        = 1
max_size        = 5
```

The public and private subnet CIDRs and Availability Zones must remain aligned by index. For example, subnet index 0 uses the first Availability Zone and its corresponding NAT gateway.

## Security Notes

- Application instances do not accept HTTP or HTTPS directly from the internet; application traffic is allowed from the ALB security group.
- IMDSv2 is required on the launch template.
- S3 versioning, server-side encryption, and all public access blocks are enabled.
- The `allow_ssh` security group currently permits SSH from `0.0.0.0/0`. Restrict this to a trusted `/32` address before using the configuration in a real environment.
- HTTPS is currently allowed by the ALB security group, but no HTTPS listener or TLS certificate is configured. Add an ACM certificate and HTTPS listener before serving production traffic over TLS.
- The deprecated `allow_http` and `allow_https` resources remain in `security_groups.tf` for reference and should not be used for new traffic paths.

## Cost and Operations

NAT gateways, public IPv4 addresses, EC2 instances, load balancer capacity, CloudWatch alarms, and S3 storage incur AWS charges. Review the plan and monitor costs before applying. The two NAT gateways improve Availability Zone independence but cost more than a single shared NAT gateway.

To remove all resources created by this project:

```bash
terraform destroy
```

Review the plan carefully before confirming destruction, especially if the S3 bucket contains data.