resource "aws_cloudwatch_log_group" "CloudWatchLogGroup" {
  name              = "${var.env}-${var.service_name}-${var.container_name}-container-logs"
  retention_in_days = 30

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_log_group" "CloudWatchLogGroup2" {
  count             = var.two_containers == "yes" ? 1 : 0
  name              = "${var.env}-${var.service_name}-${var.container_2_name}-container-logs"
  retention_in_days = 30

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "${var.env}-${var.service_name}-task-definition"
  task_role_arn            = var.task_execution_role
  execution_role_arn       = var.task_execution_role
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_mem

  dynamic "volume" {
    for_each = var.create_volume == "yes" ? [1] : []
    content {
      name = var.volume_name
      efs_volume_configuration {
        file_system_id     = var.file_system_id
        root_directory     = "/"
        transit_encryption = "ENABLED"

        authorization_config {
          access_point_id = var.access_point_id
          iam             = "DISABLED"
        }
      }
    }
  }

  container_definitions = jsonencode(
    var.two_containers == "yes" ?
    [
      {
        name         = var.container_name
        image        = var.container_image
        essential    = true
        network_mode = "awsvpc"
        command      = var.command
        user         = var.user
        mountPoints  = var.mountPoints
        entryPoint   = var.entry_point

        environment = var.task_environment_variables == [] ? null : var.task_environment_variables

        secrets = var.task_secret_environment_variables == [] ? null : var.task_secret_environment_variables

        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-group : aws_cloudwatch_log_group.CloudWatchLogGroup.name,
            awslogs-region : var.region,
            awslogs-stream-prefix : var.env
          }
        }

        portMappings = var.port_mappings
      },
      {
        name         = var.container_2_name
        image        = var.container_image
        essential    = true
        network_mode = "awsvpc"
        command      = var.command
        user         = var.user
        mountPoints  = var.mountPoints
        entryPoint   = var.entry_point_2

        environment = var.task_environment_variables == [] ? null : var.task_environment_variables

        secrets = var.task_secret_environment_variables == [] ? null : var.task_secret_environment_variables

        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-group : aws_cloudwatch_log_group.CloudWatchLogGroup2[0].name,
            awslogs-region : var.region,
            awslogs-stream-prefix : var.env
          }
        }

        portMappings = var.port_mappings_2
      }
    ]
    :
    [
      {
        name         = var.container_name
        image        = var.container_image
        essential    = true
        network_mode = "awsvpc"
        command      = var.command
        user         = var.user
        mountPoints  = var.mountPoints
        entryPoint   = var.entry_point

        environment = var.task_environment_variables == [] ? null : var.task_environment_variables

        secrets = var.task_secret_environment_variables == [] ? null : var.task_secret_environment_variables

        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-group : aws_cloudwatch_log_group.CloudWatchLogGroup.name,
            awslogs-region : var.region,
            awslogs-stream-prefix : var.env
          }
        }

        portMappings = var.port_mappings
      }
    ]
  )

}

data "aws_ecs_task_definition" "task" {
  task_definition = aws_ecs_task_definition.ecs_task_definition.family
}

resource "aws_security_group" "alb_sg" {
  count       = var.create_elb == "yes" ? 1 : 0
  name        = "allow-alb-traffic-${var.env}-${var.service_name}"
  description = "Allow ALB inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Service Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Service Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "ALB health check traffic"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "allow_alb_traffic"
  }
}

resource "aws_route53_record" "alb" {
  count = var.create_record == "yes" && var.create_elb == "yes" ? 1 : 0

  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb[0].lb_dns_name
    zone_id                = module.alb[0].lb_zone_id
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [
      weighted_routing_policy
    ]
  }
}

resource "aws_ecs_service" "ecs_service" {
  name                               = "${var.env}-${var.service_name}"
  cluster                            = var.cluster_arn
  desired_count                      = var.desired_count
  platform_version                   = "1.4.0"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  task_definition                    = "${aws_ecs_task_definition.ecs_task_definition.family}:${max(aws_ecs_task_definition.ecs_task_definition.revision, data.aws_ecs_task_definition.task.revision)}"
  propagate_tags                     = "SERVICE"
  enable_execute_command             = true

  network_configuration {
    subnets         = var.task_subnets
    security_groups = [var.task_sg]
  }
  lifecycle {
    ignore_changes = [desired_count]
  }

  dynamic "load_balancer" {
    for_each = var.create_elb == "yes" ? [1] : []
    content {
      target_group_arn = element(module.alb[0].target_group_arns, 0)
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.capacity_provider
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }

}

resource "aws_appautoscaling_target" "ecs_app_scaling" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "scale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_app_scaling.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_app_scaling.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_app_scaling.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 600
    scale_out_cooldown = 30
  }
}

resource "aws_cloudwatch_metric_alarm" "hhc" {
  count               = var.create_elb == "yes" ? 1 : 0
  alarm_name          = "No-healthy-hosts-${var.env}-${var.service_name}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This alarm monitors for when there are no healthy hosts"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = module.alb[0].lb_arn_suffix
    TargetGroup  = element(module.alb[0].target_group_arn_suffixes, 0)
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  alarm_name          = "High-Memory-Utilization-${var.env}-${var.service_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "90"
  alarm_description   = "This alarm monitors for high ECS service memory"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    ServiceName = "${var.env}-${var.service_name}"
    ClusterName = var.cluster_name
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "High-CPU-Utilization-${var.env}-${var.service_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "90"
  alarm_description   = "This alarm monitors for high ECS service CPU"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    ServiceName = "${var.env}-${var.service_name}"
    ClusterName = var.cluster_name
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_dashboard" "dash" {
  count          = var.create_elb == "yes" ? 1 : 0
  dashboard_name = "${var.env}-${var.service_name}"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 7,
          "width" : 8,
          "y" : 0,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", module.alb[0].lb_arn_suffix]
            ],
            "region" : "${var.region}",
            "stat" : "Maximum",
          }
        },
        {
          "type" : "metric",
          "x" : 8,
          "y" : 0,
          "width" : 8,
          "height" : 7,
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.alb[0].lb_arn_suffix]
            ],
            "region" : "${var.region}",
            "stat" : "Sum",
          }
        },
        {
          "type" : "metric",
          "x" : 16,
          "y" : 0,
          "width" : 8,
          "height" : 7,
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", element(module.alb[0].target_group_arn_suffixes, 0), "LoadBalancer", module.alb[0].lb_arn_suffix, { "label" : "TargetResponseTime" }]
            ],
            "region" : "${var.region}",
            "stat" : "Maximum",
          }
        },
        {
          "type" : "metric",
          "x" : 0,
          "y" : 7,
          "width" : 8,
          "height" : 6,
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", element(module.alb[0].target_group_arn_suffixes, 0), "LoadBalancer", module.alb[0].lb_arn_suffix, { "label" : "UnHealthyHostCount" }],
              [".", "HealthyHostCount", ".", ".", ".", ".", { "label" : "HealthyHostCount" }]
            ],
            "region" : "${var.region}",
            "stat" : "Maximum",
          }
        },
        {
          "height" : 6,
          "width" : 8,
          "y" : 7,
          "x" : 8,
          "type" : "metric",
          "properties" : {
            "view" : "singleValue",
            "metrics" : [
              ["ECS/ContainerInsights", "DesiredTaskCount", "ServiceName", "${var.env}-${var.service_name}", "ClusterName", var.cluster_name],
              [".", "PendingTaskCount", ".", ".", ".", "."],
              [".", "RunningTaskCount", ".", ".", ".", "."]
            ],
            "region" : "${var.region}",
            "stat" : "Maximum",
            "period" : 300
          }
        },
        {
          "height" : 6,
          "width" : 8,
          "y" : 7,
          "x" : 16,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.env}-${var.service_name}", "ClusterName", var.cluster_name]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Maximum",
            "period" : 300
          }
        },
        {
          "height" : 6,
          "width" : 8,
          "y" : 13,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.env}-${var.service_name}", "ClusterName", var.cluster_name]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Maximum",
            "period" : 300
          }
        }
      ]
    }
  )
}
