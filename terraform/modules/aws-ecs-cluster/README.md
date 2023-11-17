    module "ecs_cluster" {
      source            = "git@github.com:Credrails/terraform-modules.git//modules/aws-ecs-cluster?ref=v1.0.22"
      env               = var.env
      team              = var.team
      microservice_name = var.microservice_name
      capacity_provider = var.capacity_provider
    }
