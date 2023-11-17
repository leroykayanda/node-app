module "ecr_repo" {
  source            = "./terraform/modules/aws-ecr-repo"
  env               = var.env
  microservice_name = var.service
}
