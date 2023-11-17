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

#RDS
variable "db_instance_class" {
  type        = string
  description = "eg db.t4g.micro"
  default     = "db.m5.large"
}

variable "db_port" {
  type        = number
  description = "Port used by the db to receive traffic"
  default     = 3306
}

variable "db_engine" {
  type        = string
  description = "The database engine to use eg.mysql,postgres"
  default     = "mysql"
}

variable "db_publicly_accessible" {
  default = true
}

variable "db_engine_version" {
  type        = string
  description = "eg 14.6"
  default     = "8.0.35"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_name" {
  type    = string
  default = "abc"
}

variable "db_deletion_protection" {
  default = false
}

variable "db_multi_az" {
  default = false
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  description = "Set of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine). MySQL and MariaDB: audit, error, general, slowquery. PostgreSQL: postgresql, upgrade. MSSQL: agent , error. Oracle: alert, audit, listener, trace."
  default     = ["error", "slowquery"]
}

#redis
variable "redis_multi_az_enabled" {
  default = false
}

variable "redis_node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "redis_engine_version" {
  type    = string
  default = "7.1"
}

variable "redis_parameter_group_name" {
  type    = string
  default = "default.redis7"
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

variable "certificate_arn" {
  type        = string
  description = "Certificate for the ALB HTTPS listener"
}

variable "sns_topic" {
  type        = string
  description = "SNS topic ARN for notifications"
}

variable "prometheus_domain_name" {
  type    = string
  default = "prometheus.rentrahisi.co.ke"
}

variable "zone_id" {
  type        = string
  description = "Hosted Zone ID for the zone you want to create the ALB DNS record in"
}

variable "container_name" {
  type        = string
  description = "Name of container configured in the ECS Task Definition"
  default     = "node-app"
}

variable "desired_count" {
  type        = number
  description = "Desired number of tasks"
  default     = 1
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of fargate tasks"
  default     = 1
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of fargate tasks"
  default     = 2
}

variable "port_mappings" {
  type = list(map(number))
  default = [
    {
      containerPort = 3000
    }
  ]
}

variable "container_port" {
  type        = number
  description = "Port used by the container to receive traffic"
  default     = 3000
}

variable "domain_name" {
  type    = string
  default = "shop.rentrahisi.co.ke"
}
