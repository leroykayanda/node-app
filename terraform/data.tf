data "aws_ecr_image" "prometheus_image" {
  repository_name = module.prometheus_ecr_repo.name
  most_recent     = true
}

data "aws_ecr_image" "app_image" {
  repository_name = module.ecr_repo.name
  most_recent     = true
}
