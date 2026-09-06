# Goal Tracker AWS Architecture

This document describes the architecture implemented by the Terraform code in
this directory. The deployment is a three-tier application running in one VPC:

- Web tier: public Application Load Balancer and Node.js frontend.
- Application tier: internal Application Load Balancer and Go backend API.
- Data tier: private PostgreSQL database on Amazon RDS.

The current Terraform environment is `environments/dev`. The architecture is
modular, so the same modules can be reused for another environment by adding a
new environment root module and environment-specific variables.

## 1. Repository Structure

```text
terraform-infra/
|-- environments/
|   `-- dev/
|       |-- main.tf              Root module composition
|       |-- variables.tf         Environment input declarations
|       |-- outputs.tf           URLs, IDs, and operational commands
|       |-- providers.tf         AWS and Terraform providers
|       `-- terraform.tfvars     Dev values and CIDR ranges
|
|-- modules/
|   |-- vpc/                     VPC, subnets, routes, IGW, NAT
|   |-- security-groups/         ALB, frontend, backend, RDS, bastion rules
|   |-- iam/                     EC2 role and instance profile
|   |-- rds/                     PostgreSQL instance and DB subnet group
|   |-- secrets/                 Database credentials in Secrets Manager
|   |-- alb/                     ALB, listener, target group, health check
|   |-- frontend-asg/             Frontend launch template and ASG
|   |-- backend-asg/              Backend launch template and ASG
|   `-- bastion/                 Public administration host
|
`-- scripts/
    |-- frontend_user_data.sh    Frontend EC2 bootstrap
    |-- backend_user_data.sh     Backend EC2 bootstrap
    `-- deploy.sh                 Deployment helper
```

The application source is beside the infrastructure directory:

```text
frontend/                         Node.js and Express application
backend/                          Go and Gin API
docker-local-deployment/          Local Docker Compose files
```

## 2. Logical Architecture

```text
                                  Internet
                                      |
                         Internet Gateway (IGW)
                                      |
                    Public subnets: 10.0.1.0/24, 10.0.2.0/24
                                      |
                 +--------------------v--------------------+
                 | Public Application Load Balancer         |
                 | Listener: HTTP :80                       |
                 | Target group: frontend :3000             |
                 | Health check: GET /health                |
                 +--------------------+--------------------+
                                      |
             Frontend private subnets: 10.0.11.0/24, 10.0.12.0/24
                                      |
                 +--------------------v--------------------+
                 | Frontend Auto Scaling Group               |
                 | EC2 t3.micro instances                    |
                 | Docker: Node.js / Express                 |
                 | Host port: 3000                           |
                 +--------------------+--------------------+
                                      |
                         Internal ALB, HTTP :80
                                      |
             +------------------------v------------------------+
             | Internal Application Load Balancer                |
             | Target group: backend :8080                      |
             | Health check: GET /health                         |
             +------------------------+------------------------+
                                      |
              Backend private subnets: 10.0.21.0/24, 10.0.22.0/24
                                      |
                 +--------------------v--------------------+
                 | Backend Auto Scaling Group                  |
                 | EC2 t3.micro instances                      |
                 | Docker: Go / Gin API                        |
                 | Host port: 8080                              |
                 +--------------------+--------------------+
                                      |
              Database private subnets: 10.0.31.0/24, 10.0.32.0/24
                                      |
                 +--------------------v--------------------+
                 | Amazon RDS PostgreSQL                        |
                 | Database: goalsdb                            |
                 | Port: 5432                                   |
                 | Public access: disabled                      |
                 +---------------------------------------------+
```

## 3. Current Dev Topology

The values in `environments/dev/terraform.tfvars` define the current layout:

| Component | Current configuration |
| --- | --- |
| Region | `us-east-1` |
| Availability Zones | `us-east-1a`, `us-east-1b` |
| VPC | `10.0.0.0/16` |
| Public subnets | `10.0.1.0/24`, `10.0.2.0/24` |
| Frontend subnets | `10.0.11.0/24`, `10.0.12.0/24` |
| Backend subnets | `10.0.21.0/24`, `10.0.22.0/24` |
| Database subnets | `10.0.31.0/24`, `10.0.32.0/24` |
| NAT gateways | One, because `single_nat_gateway = true` |
| Frontend capacity | Min 2, desired 2, max 2 |
| Backend capacity | Min 1, desired 1, max 1 |
| Frontend instance type | `t3.micro` |
| Backend instance type | `t3.micro` |
| Database | PostgreSQL `15.8`, `db.t3.micro`, 20 GB gp3 |
| RDS availability | Single-AZ because `db_multi_az = false` |
| Image registry | Docker Hub |

The subnet count is four subnet groups across two Availability Zones: public,
frontend, backend, and database. That is eight subnets in total.

## 4. Terraform Module Flow

The root module in `environments/dev/main.tf` composes the infrastructure in
this dependency order:

```text
VPC
 |\
 | +--> Security groups
 | +--> IAM role and instance profile
 | +--> RDS PostgreSQL
 |       |
 |       `--> Secrets Manager database secret
 |
 +--> Bastion host
 |
 +--> Public ALB
 |       |
 |       `--> Frontend ASG
 |
 `--> Internal ALB
         |
         `--> Backend ASG
```

Terraform passes values between modules instead of hard-coding resource IDs:

1. The VPC exports subnet IDs and the VPC ID.
2. Security groups use the VPC ID and reference each other by security-group ID.
3. RDS receives database subnet IDs and the RDS security-group ID.
4. Secrets Manager receives the generated database password and RDS address.
5. The frontend ALB receives public subnet IDs and listens for frontend traffic.
6. The internal ALB receives frontend subnet IDs and routes to backend port 8080.
7. The frontend ASG receives the public target group ARN and internal ALB DNS name.
8. The backend ASG receives the internal target group ARN and secret ARN.

## 5. Network Routing

```text
Public subnet route table
  0.0.0.0/0 -> Internet Gateway

Frontend private subnet route tables
  0.0.0.0/0 -> NAT Gateway

Backend private subnet route tables
  0.0.0.0/0 -> NAT Gateway

Database subnet route tables
  No public route
```

The NAT Gateway lets private EC2 instances download packages, install AWS CLI,
and pull Docker Hub images. It does not make the instances publicly reachable.
The database remains private and is reachable only from the backend security
group on port 5432.

## 6. Security Group Flow

```text
Internet
  |
  | TCP 80/443
  v
Public ALB security group
  |
  | TCP 3000, only from ALB security group
  v
Frontend security group
  |
  | TCP 80, only from frontend security group
  v
Internal ALB security group
  |
  | TCP 8080, only from internal ALB security group
  v
Backend security group
  |
  | TCP 5432, only from backend security group
  v
RDS security group
```

SSH is intended to flow from the allowed CIDR to the bastion on port 22, and
from the bastion to frontend and backend instances on port 22. Systems Manager
is also enabled through the EC2 IAM role and is preferred for private-instance
diagnostics.

## 7. Application Request Flow

### Page request

1. The browser requests the public ALB DNS name.
2. The public ALB forwards the request to a healthy frontend instance on port
   3000.
3. Express serves the static files from `frontend/public`.
4. `GET /health` returns HTTP 200 for the ALB health check.

### API request

1. The browser sends `GET`, `POST`, or `DELETE /api/goals` to the public ALB.
2. The frontend Express server proxies the request to the internal ALB.
3. The internal ALB forwards it to a healthy backend instance on port 8080.
4. The Go API reads or writes the `goals` table in RDS PostgreSQL.
5. The backend JSON response returns through the frontend proxy to the browser.

### Database initialization

The backend bootstrap retrieves database values from Secrets Manager. The Go
application connects to PostgreSQL using SSL and creates the `goals` table if it
does not already exist.

## 8. EC2 Bootstrap and Container Flow

### Frontend instance

`scripts/frontend_user_data.sh`:

1. Installs Docker, curl, unzip, and network utilities.
2. Starts Docker and waits for the Docker daemon to become ready.
3. Installs AWS CLI v2.
4. Optionally logs in to Docker Hub.
5. Checks connectivity to the internal ALB.
6. Pulls the configured frontend image.
7. Runs the container with `-p 3000:3000` and `BACKEND_URL`.
8. Exposes the Express `/health` endpoint for the public ALB.

### Backend instance

`scripts/backend_user_data.sh`:

1. Installs Docker and database/network utilities.
2. Starts Docker and waits for the Docker daemon to become ready.
3. Installs AWS CLI v2.
4. Reads the database secret from Secrets Manager.
5. Verifies DNS resolution and TCP access to RDS port 5432.
6. Pulls the configured backend image.
7. Runs the container with `-p 8080:8080` and database environment variables.
8. Exposes the Go `/health` endpoint for the internal ALB.

If an image tag is missing from Docker Hub, the script exits during `docker
pull`; the EC2 instance can still appear running while its ALB target remains
unhealthy.

## 9. Availability and Scaling

The frontend spans two Availability Zones with two instances. The backend is
currently configured for one instance to control dev cost and account vCPU
usage. The variables can increase either ASG's minimum, desired, and maximum
capacity.

RDS is currently single-AZ. For a higher availability environment:

```hcl
single_nat_gateway = false
db_multi_az        = true
```

This creates one NAT Gateway per Availability Zone and enables Multi-AZ RDS,
but increases operating cost.

## 10. Deployment Lifecycle

```text
Developer
   |
   | docker build and docker push
   v
Docker Hub
   |
   | EC2 user-data docker pull
   v
Frontend and backend containers
   |
   | ALB health checks
   v
Healthy target groups
   |
   v
Application URL
```

When an image changes, publish it before refreshing the relevant ASG. For
production, use immutable version tags or image digests instead of relying on
the mutable `latest` tag.

## 11. Health and Troubleshooting Model

| Symptom | Most likely layer | Check |
| --- | --- | --- |
| Public URL returns 502 | Frontend target group | Public ALB target health |
| UI loads but `/api/goals` returns 500 | Backend target or database | Internal target health and backend logs |
| Target is unhealthy | Process, port, route, or security group | `/health`, Docker status, user-data log |
| No container exists | Bootstrap stopped before `docker run` | `/var/log/user-data.log` |
| Image pull says `not found` | Docker Hub repository/tag | `docker pull IMAGE:TAG` |
| ASG cannot launch EC2 | AWS vCPU quota or capacity | ASG scaling activities |
| Backend starts but database fails | Secret, RDS, or security group | RDS connectivity and secret values |

Useful checks from the dev environment:

```powershell
terraform output -raw application_url

aws elbv2 describe-target-health `
  --region us-east-1 `
  --target-group-arn TARGET_GROUP_ARN

aws ssm send-command `
  --region us-east-1 `
  --instance-ids INSTANCE_ID `
  --document-name AWS-RunShellScript `
  --parameters 'commands=["docker ps -a","docker logs --tail 100 CONTAINER_NAME"]'
```

## 12. Important Design Notes

- This implementation uses Docker Hub, not ECR.
- The public ALB and internal ALB both use the reusable `modules/alb` module.
- The internal ALB is placed in frontend subnets so the frontend can reach it;
  backend targets remain in backend subnets.
- The public application URL is an HTTP ALB DNS name. HTTPS requires supplying
  a certificate ARN to the ALB module.
- Database credentials are generated by Terraform and stored in Secrets Manager.
- Terraform state contains infrastructure metadata and must be protected. Do
  not commit sensitive state files to a public repository.
- `terraform destroy` removes the dev environment, including the database when
  the configured final-snapshot behavior allows it.
