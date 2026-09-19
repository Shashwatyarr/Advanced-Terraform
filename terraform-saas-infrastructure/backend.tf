terraform {
  backend "s3" {
    # Replace this with the actual bucket name created during the bootstrap step
    bucket         = "very-good-bucket-17"
    
    # The state file name (the workspace name is automatically prepended to this path by Terraform)
    key            = "saas-infrastructure/terraform.tfstate"
    
    region         = "us-east-1"
    
    # The DynamoDB table name created during the bootstrap step
    dynamodb_table = "saas-terraform-state-locks"
    
    # Ensures the state file is encrypted at rest in S3
    encrypt        = true
  }
}
