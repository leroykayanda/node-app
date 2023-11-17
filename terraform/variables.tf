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

