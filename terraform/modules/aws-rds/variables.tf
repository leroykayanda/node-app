variable "env" {
  type        = string
  description = "Deployment environment eg prod, dev"
}

variable "microservice_name" {
  type        = string
  description = "Name of the service"
}

variable "team" {
  type        = string
  description = "For resource tags"
}

variable "db_subnets" {
  type        = list(string)
  description = "subnets to create the db in"
}

variable "instance_class" {
  type        = string
  description = "eg db.t4g.micro"
}

variable "sns_topic" {
  type        = string
  description = "SNS topic ARN for notifications"
  default     = ""
}

variable "security_group_id" {
  type = string
}

variable "username" {
  type = string
}

variable "storage_throughput" {
  default = null
}

variable "iops" {
  default = null
}

variable "password" {
  type = string
}

variable "performance_insights_retention_period" {
  type    = number
  default = 31
}

variable "backup_retention_period" {
  type    = number
  default = 35
}

variable "port" {
  type = number
}

variable "create_cpu_credit_alarm" {
  type        = string
  description = "Create alarm only if a burstable instance class has been chosen. Possible values - yes or no"
  default     = "no"
}

variable "maintenance_window" {
  type        = string
  description = "eg Mon:00:00-Mon:03:00"
  default     = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  type        = string
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Must not overlap with maintenance_window.Eg: 00:00-02:00"
  default     = "04:00-06:00"
}

variable "allocated_storage" {
  type        = number
  description = "The allocated storage in gibibytes"
  default     = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 1000
}

variable "db_name" {
  type        = string
  description = "The name of the database to create when the DB instance is created."
}

variable "deletion_protection" {
  default = true
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  description = "Set of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine). MySQL and MariaDB: audit, error, general, slowquery. PostgreSQL: postgresql, upgrade. MSSQL: agent , error. Oracle: alert, audit, listener, trace. eg ['postgresql']"
}

variable "engine" {
  type        = string
  description = "The database engine to use eg.mysql,postgres"
}

variable "engine_version" {
  type        = string
  description = "eg 14.6"
}

variable "multi_az" {
}

variable "memory_alarm_threshold" {
  type        = number
  description = "Threshold for memory DB alarm to trigger in bytes"
  default     = 1000
}

variable "storage_alarm_threshold" {
  type        = number
  description = "gb"
  default     = 5
}

variable "iops_alarm_threshold" {
  type    = number
  default = 1000
}

variable "throughput_alarm_threshold" {
  type    = number
  default = 1000
}

variable "queue_depth_alarm_threshold" {
  type    = number
  default = 1000
}

variable "region" {
  type = string
}

variable "publicly_accessible" {
  default = false
}
