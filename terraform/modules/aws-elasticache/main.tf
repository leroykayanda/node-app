resource "aws_security_group" "redis_security_group" {
  name        = "${var.env}-${var.microservice_name}-allow-redis-traffic"
  description = "Allow redis inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis Traffic"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_kms_key" "kms_key" {
  description             = "Encrypts redis for ${var.env}-${var.microservice_name}"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "redis_log_group" {
  name              = "${var.env}-${var.microservice_name}-redis-logs"
  retention_in_days = 30
}

resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  name       = "${var.env}-${var.microservice_name}"
  subnet_ids = var.private_subnets
}

resource "aws_elasticache_replication_group" "elasticache_cluster" {

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  replication_group_id = lower("${var.env}-${var.microservice_name}")

  description                = "Elasticache for use by celery"
  engine                     = "redis"
  node_type                  = var.node_type
  engine_version             = var.engine_version
  num_cache_clusters         = var.num_cache_clusters
  parameter_group_name       = var.parameter_group_name
  port                       = 6379
  apply_immediately          = true
  auto_minor_version_upgrade = true
  maintenance_window         = "sat:22:00-sat:23:00"
  security_group_ids         = [aws_security_group.redis_security_group.id]
  subnet_group_name          = aws_elasticache_subnet_group.elasticache_subnet_group.name
  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.kms_key.arn

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_log_group.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_CPUUtilization" {
  alarm_name          = "${var.env}-${var.microservice_name}-Redis-High-CPUUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm monitors for high CPU"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    CacheClusterId = element(tolist(aws_elasticache_replication_group.elasticache_cluster.member_clusters), 0)
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_CPUCreditBalance" {
  alarm_name          = "${var.env}-${var.microservice_name}-Redis-Low-CPUCreditBalance"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This alarm monitors for depleted CPU credits"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    CacheClusterId = element(tolist(aws_elasticache_replication_group.elasticache_cluster.member_clusters), 0)
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_FreeableMemory" {
  alarm_name          = "${var.env}-${var.microservice_name}-Redis-Low-FreeableMemory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "50000000"
  alarm_description   = "This alarm monitors for low memory"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    CacheClusterId = element(tolist(aws_elasticache_replication_group.elasticache_cluster.member_clusters), 0)
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}
