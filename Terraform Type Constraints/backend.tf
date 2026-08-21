terraform {
  backend "s3" {
    bucket = "shashwatsrivastava-terraform-state" //an s3 bucket that you have to create before hand with the same name
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}