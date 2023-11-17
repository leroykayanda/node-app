variable "microservice_name" {
  type        = string
  description = "Name of the ECS service"
}

variable "env" {
  type        = string
  description = "Deployment environment eg prod, dev"
}
