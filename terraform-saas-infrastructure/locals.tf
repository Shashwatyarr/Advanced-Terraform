locals {
  # Dynamically fetch the current Terraform workspace (e.g., dev, test, prod).
  # This serves as the single source of truth for the active environment 
  # throughout the entire infrastructure deployment.
  environment = terraform.workspace
}
