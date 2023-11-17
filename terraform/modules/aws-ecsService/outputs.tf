output "cloudwatch_loggroup" {
  value = aws_cloudwatch_log_group.CloudWatchLogGroup.name
}

output "alb_dns_name" {
  value = var.create_elb == "yes" ? module.alb[0].lb_dns_name : null
}

output "alb_arn" {
  value = var.create_elb == "yes" ? module.alb[0].lb_arn : null
}

variable "capacity_provider" {
  type        = string
  description = "Short name of the ECS capacity provider"
}

output "loggroup_arn" {
  value = aws_cloudwatch_log_group.CloudWatchLogGroup.arn
}

output "loggroup_arn_2" {
  value = var.two_containers == "yes" ? aws_cloudwatch_log_group.CloudWatchLogGroup2[0].arn : null
}

output "loggroup_name" {
  value = aws_cloudwatch_log_group.CloudWatchLogGroup.name
}

output "loggroup_name_2" {
  value = var.two_containers == "yes" ? aws_cloudwatch_log_group.CloudWatchLogGroup2[0].name : null
}
