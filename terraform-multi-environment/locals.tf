locals {
  # Determine environment: prioritize terraform.workspace, fallback to var.environment_override if workspace is default
  environment = terraform.workspace == "default" ? (var.environment_override != "" ? var.environment_override : "dev") : terraform.workspace

  # Environment configuration map mapping the active workspace to compute values
  environment_config = {
    dev = {
      instance_type  = "t3.micro"
      instance_count = 1
    }
    prod = {
      instance_type  = "t3.small"
      instance_count = 3
    }
  }

  # Safely fetch the configuration for the active environment (fallback to dev if unknown)
  active_config = contains(keys(local.environment_config), local.environment) ? local.environment_config[local.environment] : local.environment_config["dev"]

  # Final resolution for instance specs: TFVars overrides take precedence > Environment Map
  final_instance_type  = var.instance_type != "" ? var.instance_type : local.active_config.instance_type
  final_instance_count = var.instance_count != 0 ? var.instance_count : local.active_config.instance_count

  # Common tags applied to all supported resources
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}
