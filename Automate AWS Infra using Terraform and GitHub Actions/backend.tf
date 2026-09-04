terraform {
  backend "s3" {
    bucket       = "2360476128401834561" # Replace with your S3 bucket name
    key          = "terraform/state/main/terraform.tfstate"
    region       = "us-east-1" # Replace with your region
    use_lockfile = true        # S3 Native Locking (No DynamoDB needed)
    encrypt      = true
  }
}
