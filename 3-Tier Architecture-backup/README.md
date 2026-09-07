# Goal Tracker: AWS 3-Tier Architecture

This project deploys a small goal-tracking application on AWS using Terraform.
The application has three logical tiers:

1. Web tier: an internet-facing Application Load Balancer and a Node.js frontend.
2. Application tier: an internal Application Load Balancer and a Go API.
3. Data tier: PostgreSQL on Amazon RDS in private database subnets.

The frontend and backend run as Docker containers on EC2 instances managed by
Auto Scaling Groups. Docker images are stored in Docker Hub.

## Repository Layout

```text
frontend/                         Node.js/Express UI and API proxy
backend/                          Go/Gin API and PostgreSQL access
docker-local-deployment/          Local Docker Compose setup
terraform-infra/
  environments/dev/               Dev root module and terraform.tfvars
  modules/vpc/                    VPC and subnet module
  modules/alb/                    ALB, listeners, target groups, health checks
  modules/frontend-asg/            Frontend launch template and ASG
  modules/backend-asg/             Backend launch template and ASG
  modules/rds/                    PostgreSQL database
  modules/secrets/                Database credentials in Secrets Manager
  modules/security-groups/         Network access rules
  modules/iam/                    EC2 instance role and policies
  scripts/                        EC2 user-data bootstrap scripts
```

Run Terraform commands from `terraform-infra/environments/dev`.

## Architecture

![AWS 3-Tier Architecture Diagram](./Screenshot%202026-09-07%20093936.png)

```text
                                   Internet
                                      |
                         Internet Gateway / public subnets
                                      |
             +------------------------v------------------------+
             | Public ALB :80                                    |
             | Target group -> frontend instances :3000           |
             +------------------------+------------------------+
                                      |
                         Frontend private subnets
                                      |
             +------------------------v------------------------+
             | Frontend ASG: Node.js + Express + Docker            |
             | Serves the UI and proxies /api/* requests           |
             +------------------------+------------------------+
                                      |
                         Frontend-to-internal-ALB traffic
                                      |
             +------------------------v------------------------+
             | Internal ALB :80                                    |
             | Target group -> backend instances :8080             |
             +------------------------+------------------------+
                                      |
                          Backend private subnets
                                      |
             +------------------------v------------------------+
             | Backend ASG: Go + Gin + Docker                       |
             | Reads credentials from Secrets Manager                |
             +------------------------+------------------------+
                                      |
                          Database private subnets
                                      |
             +------------------------v------------------------+
             | RDS PostgreSQL :5432                                |
             | Database: goalsdb                                    |
             +----------------------------------------------------+
```

The dev configuration uses two Availability Zones, one NAT Gateway, two
frontend instances, one backend instance, and a single-AZ `db.t3.micro` RDS
instance. Set `single_nat_gateway = false` and `db_multi_az = true` when the
environment needs higher availability and the additional cost is acceptable.

## End-to-End Request Flow

### Page load

1. The browser resolves the public ALB DNS name.
2. The public ALB listener on port 80 selects a healthy frontend target on port
   3000.
3. Express serves `frontend/public/index.html` and its static assets.
4. The ALB health check calls `GET /health` on every frontend instance. A
   healthy response is HTTP 200.

### Read or create a goal

1. The browser calls `/api/goals` on the same public ALB.
2. The frontend Express server proxies that request to the internal ALB.
3. The internal ALB selects the healthy Go backend on port 8080.
4. The backend queries or updates the `goals` table in PostgreSQL.
5. The JSON response travels back through the backend ALB, frontend proxy, and
   public ALB to the browser.

The backend health check is `GET /health` on port 8080. The backend creates the
`goals` table if it does not already exist.

## Network and Security Boundaries

- Public ALB: accepts HTTP/HTTPS from the internet.
- Frontend instances: accept port 3000 only from the public ALB security group.
- Internal ALB: accepts port 80 only from the frontend security group.
- Backend instances: accept port 8080 only from the internal ALB security group.
- RDS: accepts PostgreSQL port 5432 only from the backend security group.
- Bastion: provides SSH access to private instances through its security group.
- Private instances use the NAT Gateway for outbound package and Docker Hub
  access; they do not receive public IP addresses.
- Database credentials are read at boot from AWS Secrets Manager.

## Prerequisites

- AWS CLI configured for the target AWS account and region.
- Terraform installed.
- Docker Desktop or another Docker engine.
- A Docker Hub account and repository access.
- An EC2 key pair in the selected AWS region.

The EC2 role also needs permissions for Systems Manager, Secrets Manager, and
CloudWatch. The Terraform IAM module creates these permissions.

## Deploy From Scratch

### 1. Build and publish both images

```powershell
docker login

docker build -t YOUR_USERNAME/goal-tracker-frontend:latest ./frontend
docker push YOUR_USERNAME/goal-tracker-frontend:latest

docker build -t YOUR_USERNAME/goal-tracker-backend:latest ./backend
docker push YOUR_USERNAME/goal-tracker-backend:latest
```

The repositories must exist and the image tags in Terraform must match the
published names. A missing Docker Hub tag causes the EC2 bootstrap to stop
before `docker run`, leaving the ALB targets unhealthy.

### 2. Configure the dev environment

```powershell
cd terraform-infra/environments/dev
Copy-Item terraform.tfvars.example terraform.tfvars
```

Set at least these values in `terraform.tfvars`:

```hcl
region      = "us-east-1"
environment = "dev"
project     = "goal-tracker"

ssh_key_name     = "YOUR_EC2_KEY_PAIR"
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"

frontend_docker_image = "YOUR_USERNAME/goal-tracker-frontend:latest"
backend_docker_image  = "YOUR_USERNAME/goal-tracker-backend:latest"
```

For public Docker Hub repositories, leave the Docker Hub credentials empty.
For private repositories, use a Docker Hub access token rather than an account
password.

### 3. Apply Terraform

```powershell
terraform init
terraform validate
terraform plan
terraform apply
```

Get the deployed endpoints after apply:

```powershell
terraform output -raw application_url
terraform output -raw alb_dns_name
terraform output -raw bastion_public_ip
```

Initial deployment takes several minutes because AWS creates networking, RDS,
load balancers, EC2 instances, and Docker services.

## Updating the Application

The EC2 user-data scripts pull the image during instance startup. Because the
`latest` tag is mutable, publish the image first and then refresh the relevant
ASG so new instances pull it.

```powershell
docker build -t YOUR_USERNAME/goal-tracker-frontend:latest ./frontend
docker push YOUR_USERNAME/goal-tracker-frontend:latest

docker build -t YOUR_USERNAME/goal-tracker-backend:latest ./backend
docker push YOUR_USERNAME/goal-tracker-backend:latest

aws autoscaling start-instance-refresh `
  --auto-scaling-group-name dev-goal-tracker-frontend-asg `
  --preferences MinHealthyPercentage=50,InstanceWarmup=120 `
  --region us-east-1

aws autoscaling start-instance-refresh `
  --auto-scaling-group-name dev-goal-tracker-backend-asg `
  --preferences MinHealthyPercentage=0,InstanceWarmup=120 `
  --region us-east-1
```

For production, immutable image tags or image digests are preferable to
`latest`, because they make rollbacks and instance refreshes deterministic.

## Operational Checks

```powershell
$publicTg = aws elbv2 describe-target-groups --region us-east-1 `
  --names dev-goal-tracker-public-tg `
  --query 'TargetGroups[0].TargetGroupArn' --output text

aws elbv2 describe-target-health --region us-east-1 `
  --target-group-arn $publicTg

curl.exe -i http://PUBLIC_ALB_DNS_NAME/health
curl.exe -i http://PUBLIC_ALB_DNS_NAME/api/goals
```

Healthy public and internal target groups are required for a working
application. A public ALB `502` generally means that no frontend target is
healthy. A frontend `/api/goals` `500` generally means the frontend is running
but the internal backend target or database path is failing.

## Troubleshooting

### Frontend ALB returns 502

```powershell
aws elbv2 describe-target-health --region us-east-1 `
  --target-group-arn PUBLIC_TARGET_GROUP_ARN
aws autoscaling describe-auto-scaling-groups --region us-east-1 `
  --auto-scaling-group-names dev-goal-tracker-frontend-asg
```

Then use Systems Manager to inspect a private instance without opening SSH:

```powershell
aws ssm send-command --region us-east-1 `
  --instance-ids INSTANCE_ID `
  --document-name AWS-RunShellScript `
  --parameters 'commands=["docker ps -a","tail -n 80 /var/log/user-data.log"]'
```

Common causes are a missing Docker Hub image, Docker not being ready during
bootstrap, or a frontend process that is not listening on port 3000.

### Frontend API returns 500

Check the internal target group and backend bootstrap log:

```powershell
aws elbv2 describe-target-health --region us-east-1 `
  --target-group-arn INTERNAL_TARGET_GROUP_ARN

aws ssm send-command --region us-east-1 `
  --instance-ids BACKEND_INSTANCE_ID `
  --document-name AWS-RunShellScript `
  --parameters 'commands=["docker ps -a","docker logs --tail 100 goal-tracker-backend"]'
```

The backend also requires successful DNS and TCP connectivity to RDS, valid
Secrets Manager values, and the Docker image
`YOUR_USERNAME/goal-tracker-backend:latest`.

### ASG cannot launch another instance

AWS may report that the account has exceeded its regional vCPU limit. Check:

```powershell
aws autoscaling describe-scaling-activities `
  --region us-east-1 `
  --auto-scaling-group-name dev-goal-tracker-backend-asg
```

Terminate unused instances or request an EC2 vCPU quota increase. During an
instance refresh, an old instance may also temporarily consume capacity while
it is draining from the load balancer.

## Local Development

```powershell
cd docker-local-deployment
docker compose up -d
```

The local frontend is available at `http://localhost:3000`.

## Destroy the Dev Environment

Review the resources carefully before destroying them. This removes the VPC,
load balancers, EC2 instances, RDS database, secrets, and related resources.

```powershell
cd terraform-infra/environments/dev
terraform destroy
```

## Technology Stack

Terraform, AWS VPC, Application Load Balancer, EC2 Auto Scaling, Docker, Node.js,
Express, Go, Gin, PostgreSQL, RDS, Secrets Manager, IAM, Systems Manager, NAT
Gateway, and CloudWatch.
