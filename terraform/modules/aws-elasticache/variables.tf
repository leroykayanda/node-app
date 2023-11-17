variable "env" {
  type        = string
  description = "Deployment environment eg prod, dev"
}

variable "microservice_name" {
  type        = string
  description = "Name of the ECS service"
}

variable "team" {
  type        = string
  description = "For resource tags"
}

variable "vpc_id" {
  type = string
}

variable "sns_topic" {
  type        = string
  description = "SNS topic ARN for notifications"
  default     = ""
}

variable "vpc_cidr" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "multi_az_enabled" {
  default = false
}

variable "automatic_failover_enabled" {
  default = false
}

variable "num_cache_clusters" {
  type        = number
  description = "Number of redis nodes"
  default     = 1
}

variable "node_type" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "parameter_group_name" {
  type = string
}
