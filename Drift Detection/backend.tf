# Remote State Backend Configuration
# This file configures S3 backend for state management with S3 native locking
# Each environment (dev/prod) will have a separate state file
# Requires Terraform 1.10.0+ for use_lockfile support

terraform {
  backend "s3" {
    # Backend configuration is provided via backend-dev.hcl or backend-prod.hcl.
    # This keeps dev and prod state files separate and avoids using a stale placeholder bucket.
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
