module "ecr_repo" {
  source            = "./modules/aws-ecr-repo"
  env               = var.env
  microservice_name = var.service
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

/* module "prometheus_ecs_service" {
      source                            = "./modules/aws-ecsService"
      cluster_arn                       = module.ecs_cluster.ecs_cluster_arn
      cluster_name                      = module.ecs_cluster.name
      container_image                   = var.container_image
      container_name                    = var.container_name
      env                               = var.env
      region                            = var.region
      service_name                      = var.microservice_name
      task_execution_role               = aws_iam_role.ExecutionRole.arn
      fargate_cpu                       = var.fargate_cpu
      fargate_mem                       = var.fargate_mem
      task_environment_variables        = var.task_environment_variables
      task_secret_environment_variables = var.task_secret_environment_variables
      desired_count                     = var.desired_count
      task_subnets                      = var.task_subnets
      vpc_id                            = var.vpc_id
      vpc_cidr                          = var.vpc_cidr
      internal                          = var.internal
      alb_subnets                       = var.alb_subnets
      deregistration_delay              = var.deregistration_delay
      health_check_path                 = var.health_check_path
      certificate_arn                   = var.certificate_arn
      min_capacity                      = var.min_capacity
      max_capacity                      = var.max_capacity
      sns_topic                         = var.sns_topic
      team                              = var.team
      capacity_provider                 = var.capacity_provider
      company_name                      = var.company_name
      task_sg                           = aws_security_group.task_sg.id #optional variables follow
      command                           = var.command
      user                              = var.user
      create_volume                     = "yes"
      volume_name                       = "worker-logs"
      file_system_id                    = module.efs.id
      mountPoints                       = var.mountPoints
      access_point_id                   = module.efs.access_point_id
      set_identifier                    = var.set_identifier
      record_weight                     = var.record_weight
      idle_timeout                      = var.idle_timeout
      create_record                     = var.create_record
      two_containers                    = var.two_containers
      container_2_name                  = var.container_2_name
      entry_point                       = var.entry_point
      entry_point_2                     = var.entry_point_2
      create_elb                        = var.create_elb
      container_port                    = var.container_port
      port_mappings                     = var.port_mappings
      port_mappings_2                   = var.port_mappings_2
      domain_name                       = var.domain_name
      zone_id                           = var.zone_id
      waf                               = var.waf
      health_check_grace_period_seconds = var.health_check_grace_period_seconds
    } */
