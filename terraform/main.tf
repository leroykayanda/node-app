module "ecr_repo" {
  source            = "./modules/aws-ecr-repo"
  env               = var.env
  microservice_name = var.service
}

module "prometheus_ecr_repo" {
  source            = "./modules/aws-ecr-repo"
  env               = var.env
  microservice_name = "${var.service}-prometheus"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.env}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Team        = var.team
    Environment = var.env
  }
}

module "ecs_cluster" {
  source            = "./modules/aws-ecs-cluster"
  env               = var.env
  team              = var.team
  microservice_name = var.service
  capacity_provider = var.capacity_provider
}

module "prometheus_ecs_service" {
  source                            = "./modules/aws-ecsService"
  cluster_arn                       = module.ecs_cluster.arn
  cluster_name                      = module.ecs_cluster.name
  container_image                   = "${module.prometheus_ecr_repo.repository_url}:${local.prometheus_image_tag}"
  container_name                    = "prometheus"
  env                               = var.env
  region                            = var.region
  service_name                      = "prometheus"
  task_execution_role               = aws_iam_role.prometheus_execution_role.arn
  fargate_cpu                       = 1024
  fargate_mem                       = 2048
  task_environment_variables        = []
  task_secret_environment_variables = []
  desired_count                     = 1
  task_subnets                      = module.vpc.private_subnets
  vpc_id                            = module.vpc.vpc_id
  vpc_cidr                          = module.vpc.vpc_cidr_block
  alb_subnets                       = module.vpc.public_subnets
  certificate_arn                   = var.certificate_arn
  min_capacity                      = 1
  max_capacity                      = 1
  sns_topic                         = var.sns_topic
  team                              = var.team
  capacity_provider                 = var.capacity_provider
  container_port                    = var.prometheus_container_port
  port_mappings                     = var.prometheus_port_mappings
  domain_name                       = var.prometheus_domain_name
  zone_id                           = var.zone_id
  task_sg                           = aws_security_group.prometheus_task_sg.id
}

module "rds" {
  source                          = "./modules/aws-rds"
  env                             = var.env
  team                            = var.team
  microservice_name               = var.service
  db_subnets                      = module.vpc.public_subnets
  instance_class                  = var.db_instance_class
  sns_topic                       = var.sns_topic
  security_group_id               = aws_security_group.db_sg.id
  engine                          = var.db_engine
  publicly_accessible             = var.db_publicly_accessible
  engine_version                  = var.db_engine_version
  username                        = var.db_username
  password                        = var.db_password
  port                            = var.db_port
  db_name                         = var.db_name
  deletion_protection             = var.db_deletion_protection
  multi_az                        = var.db_multi_az
  region                          = var.region
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
}

module "redis" {
  source               = "./modules/aws-elasticache"
  env                  = var.env
  microservice_name    = var.service
  team                 = var.team
  vpc_id               = module.vpc.vpc_id
  sns_topic            = var.sns_topic
  vpc_cidr             = module.vpc.vpc_cidr_block
  private_subnets      = module.vpc.public_subnets
  multi_az_enabled     = var.redis_multi_az_enabled
  node_type            = var.redis_node_type
  engine_version       = var.redis_engine_version
  parameter_group_name = var.redis_parameter_group_name
}

module "app_ecs_service" {
  source                            = "./modules/aws-ecsService"
  cluster_arn                       = module.ecs_cluster.arn
  cluster_name                      = module.ecs_cluster.name
  container_image                   = "${module.ecr_repo.repository_url}:${local.app_image_tag}"
  container_name                    = var.container_name
  env                               = var.env
  region                            = var.region
  service_name                      = var.service
  task_execution_role               = aws_iam_role.prometheus_execution_role.arn
  fargate_cpu                       = var.fargate_cpu
  fargate_mem                       = var.fargate_mem
  task_environment_variables        = local.app_env_variables
  task_secret_environment_variables = []
  desired_count                     = var.desired_count
  task_subnets                      = module.vpc.private_subnets
  vpc_id                            = module.vpc.vpc_id
  vpc_cidr                          = module.vpc.vpc_cidr_block
  alb_subnets                       = module.vpc.public_subnets
  certificate_arn                   = var.certificate_arn
  min_capacity                      = var.min_capacity
  max_capacity                      = var.max_capacity
  sns_topic                         = var.sns_topic
  team                              = var.team
  capacity_provider                 = var.capacity_provider
  port_mappings                     = var.port_mappings
  container_port                    = var.container_port
  task_sg                           = aws_security_group.app_sg.id
  domain_name                       = var.domain_name
  zone_id                           = var.zone_id
}

