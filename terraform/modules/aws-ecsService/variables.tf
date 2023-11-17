
variable "service_name" {
  type        = string
  description = "Name of the ECS service"
}

variable "cluster_arn" {
  type        = string
  description = "ARN of cluster to add this service to"
}

variable "task_execution_role" {
  type = string
}

variable "fargate_cpu" {
  type        = number
  description = "Number of cpu units used by a Fargate task"
  default     = 1
}

variable "fargate_mem" {
  type        = number
  description = "Amount (in MiB) of memory used by the task"
  default     = 2048
}

variable "container_name" {
  type        = string
  description = "Name of the container"
}

variable "container_image" {
  type = string
}

variable "task_environment_variables" {
  type    = list(map(string))
  default = []
}

variable "task_secret_environment_variables" {
  type    = list(map(string))
  default = []
}

variable "region" {
  type = string
}

variable "env" {
  type        = string
  description = "Deployment environment eg prod, dev"
}

variable "container_port" {
  type        = number
  description = "Port used by the container to receive traffic"
  default     = null
}

variable "desired_count" {
  type        = string
  description = "Desired number of tasks"
}

variable "task_subnets" {
  type        = list(string)
  description = "Private subnets to be used to launch the ECS tasks"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "internal" {
  type        = string
  description = "Boolean - whether the ALB is internal or not"
  default     = false
}

variable "alb_subnets" {
  type        = list(string)
  description = "Subnets for an ALB - can be public or private"
  default     = []
}

variable "deregistration_delay" {
  type        = number
  description = "ALB target group deregistration delay"
  default     = 5
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = "/"
}

variable "certificate_arn" {
  type        = string
  description = "Certificate for the ALB HTTPS listener"
}

variable "waf" {
  type        = string
  description = "Tag used by AWS Firewall manager to determine whether or not to associate a WAF. Value can be yes or no "
  default     = "yes"
}

variable "zone_id" {
  type        = string
  description = "Hosted Zone ID for the zone you want to create the ALB DNS record in"
  default     = null
}

variable "min_capacity" {
  type        = number
  description = "Minimum no. of tasks"
}

variable "domain_name" {
  type        = string
  description = "DNS name in your hosted zone that you want to point to the ALB"
  default     = null
}

variable "max_capacity" {
  type        = number
  description = "Maximum no. of tasks"
}

variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "sns_topic" {
  type        = string
  description = "SNS topic ARN for notifications"
  default     = ""
}

variable "team" {
  type        = string
  description = "Used to tag resources"
}

variable "company_name" {
  type    = string
  default = "abc"
}

variable "command" {
  type    = list(string)
  default = []
}

variable "user" {
  type    = string
  default = null
}

variable "task_sg" {
  type        = string
  description = "Task security group"
}

variable "create_volume" {
  type        = string
  description = "yes or no - conrols whether the task has a volume or not"
  default     = "no"
}

variable "volume_name" {
  type        = string
  description = "Name of the volume"
  default     = ""
}

variable "file_system_id" {
  type        = string
  description = "EFS"
  default     = ""
}

variable "mountPoints" {
  type        = list(map(string))
  description = "EFS"
  default     = []
}

variable "access_point_id" {
  type        = string
  description = "EFS"
  default     = ""
}

variable "set_identifier" {
  type    = string
  default = "main-region"
}

variable "record_weight" {
  type    = number
  default = 100
}

variable "idle_timeout" {
  type        = number
  description = "ALB idle timeout"
  default     = 60
}

variable "create_record" {
  type    = string
  default = "yes"
}

variable "two_containers" {
  type    = string
  default = "no"
}

variable "container_2_name" {
  type    = string
  default = null
}

variable "entry_point" {
  type    = list(string)
  default = []
}

variable "entry_point_2" {
  type    = list(string)
  default = []
}

variable "port_mappings" {
  type    = list(map(number))
  default = []
}

variable "port_mappings_2" {
  type    = list(map(number))
  default = []
}

variable "create_elb" {
  type    = string
  default = "yes"
}

variable "health_check_grace_period_seconds" {
  type    = number
  default = 300
}
