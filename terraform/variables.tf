#general

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "service" {
  type        = string
  description = "The name of the product or service being built"
  default     = "node-app"
}

variable "env" {
  type        = string
  description = "The environment i.e prod, dev etc"
  default     = "prod"
}

variable "team" {
  type        = string
  description = "Used to tag resources"
  default     = "devops"
}

#ecs
variable "capacity_provider" {
  type        = string
  description = "Short name of the ECS capacity provider"
  default     = "FARGATE"
}

variable "prometheus_port_mappings" {
  type = list(map(number))
  default = [
    {
      containerPort = 9090
    }
  ]
}

variable "prometheus_container_port" {
  type        = number
  description = "Port used by the container to receive traffic"
  default     = 9090
}
