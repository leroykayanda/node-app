module "ecr_repo" {
  source            = "./modules/aws-ecr-repo"
  env               = var.env
  microservice_name = var.service
}
