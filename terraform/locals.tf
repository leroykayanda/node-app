locals {
  prometheus_image_tag = element(data.aws_ecr_image.prometheus_image.image_tags, 0)
  app_image_tag        = element(data.aws_ecr_image.app_image.image_tags, 0)

  app_env_variables = [
    {
      name  = "DB_HOST"
      value = module.rds.address
    },
    {
      name  = "DB_USER"
      value = var.db_username
    },
    {
      name  = "DB_PASS"
      value = var.db_password
    },
    {
      name  = "DB_NAME"
      value = var.db_name
    },
    {
      name  = "REDIS_URL"
      value = "redis://${module.redis.primary_endpoint_address}:6379/0"
    },
    {
      name  = "APPLICATION_PORT"
      value = 3000
    }
  ]
}
