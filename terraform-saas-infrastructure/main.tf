# ==============================================================================
# CORE INFRASTRUCTURE
# ==============================================================================

module "vpc" {
  source = "./modules/vpc"

  environment              = local.environment
  vpc_cidr                 = var.vpc_cidr
  public_subnets_cidr      = var.public_subnets_cidr
  private_app_subnets_cidr = var.private_app_subnets_cidr
  private_db_subnets_cidr  = var.private_db_subnets_cidr
  availability_zones       = var.availability_zones
  enable_nat_gateway       = var.enable_nat_gateway
  single_nat_gateway       = var.single_nat_gateway
}

module "security_groups" {
  source = "./modules/security_groups"

  environment = local.environment
  vpc_id      = module.vpc.vpc_id
  app_port    = var.app_port
  db_port     = var.db_port
}

module "iam" {
  source = "./modules/iam"

  environment   = local.environment
  s3_bucket_arn = module.s3.bucket_arn
}

# ==============================================================================
# APPLICATION LAYER (ALB & ASG)
# ==============================================================================

module "alb" {
  source = "./modules/alb"

  environment           = local.environment
  vpc_id                = module.vpc.vpc_id
  public_subnets        = module.vpc.public_subnets
  alb_security_group_id = module.security_groups.alb_sg_id
}

module "autoscaling" {
  source = "./modules/autoscaling"

  environment               = local.environment
  instance_type             = var.ec2_instance_type
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  vpc_zone_identifier       = module.vpc.private_app_subnets
  target_group_arns         = [module.alb.target_group_arn]
  app_security_group_id     = module.security_groups.app_sg_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
}

# ==============================================================================
# DATA LAYER (RDS & S3)
# ==============================================================================

module "rds" {
  source = "./modules/rds"

  environment             = local.environment
  db_subnet_group_name    = module.vpc.db_subnet_group_name
  db_security_group_id    = module.security_groups.db_sg_id
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  db_name                 = var.db_name
  db_username             = var.db_username
  multi_az                = var.db_multi_az
  deletion_protection     = var.db_deletion_protection
  backup_retention_period = var.db_backup_retention_period
}

module "s3" {
  source = "./modules/s3"

  environment        = local.environment
  bucket_name_prefix = var.s3_bucket_name_prefix
}

# ==============================================================================
# MONITORING LAYER (CloudWatch)
# ==============================================================================

module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment             = local.environment
  asg_name                = module.autoscaling.asg_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  alert_email             = var.alert_email
}
