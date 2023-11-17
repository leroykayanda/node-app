resource "aws_db_subnet_group" "subnet_group" {
  name        = "${var.env}-${var.microservice_name}"
  subnet_ids  = var.db_subnets
  description = "Private subnets for the db"
}

resource "aws_kms_key" "kms_key" {
  description = "Encrypts the ${var.env}-${var.microservice_name} db"

  deletion_window_in_days = 7

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage                     = var.allocated_storage
  max_allocated_storage                 = var.max_allocated_storage
  apply_immediately                     = true
  auto_minor_version_upgrade            = true
  backup_retention_period               = var.backup_retention_period
  db_name                               = var.db_name
  db_subnet_group_name                  = aws_db_subnet_group.subnet_group.name
  delete_automated_backups              = true
  deletion_protection                   = var.deletion_protection
  engine                                = var.engine
  engine_version                        = var.engine_version
  final_snapshot_identifier             = "${var.env}-${var.microservice_name}"
  identifier                            = "${var.env}-${var.microservice_name}"
  instance_class                        = var.instance_class
  kms_key_id                            = aws_kms_key.kms_key.arn
  multi_az                              = var.multi_az
  storage_encrypted                     = true
  username                              = var.username
  password                              = var.password
  skip_final_snapshot                   = false
  port                                  = var.port
  performance_insights_enabled          = true
  performance_insights_retention_period = var.performance_insights_retention_period
  vpc_security_group_ids                = [var.security_group_id]
  maintenance_window                    = var.maintenance_window
  backup_window                         = var.backup_window
  iops                                  = var.iops
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  storage_type                          = "gp3"
  storage_throughput                    = var.storage_throughput
  publicly_accessible                   = var.publicly_accessible

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_CPUUtilization" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-CPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "80"
  alarm_description   = "This alarm monitors for high database CPU"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db_instance.id
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_FreeStorageSpace" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-Low-Storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Minimum"
  threshold           = var.storage_alarm_threshold
  alarm_description   = "This alarm monitors for database storage"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db_instance.id
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_FreeableMemory" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-Low-Memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Minimum"
  threshold           = var.memory_alarm_threshold
  alarm_description   = "This alarm monitors for low database memory"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db_instance.id
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_CPUCreditBalance" {
  count               = var.create_cpu_credit_alarm == "yes" ? 1 : 0
  alarm_name          = "${var.env}-${var.microservice_name}-DB-Low-CPUCreditBalance"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This alarm monitors for low CPUCreditBalance"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db_instance.id
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_ReadLatency" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-ReadLatency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "This alarm monitors for high read latency"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db_instance.id
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_WriteLatency" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-WriteLatency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "This alarm monitors for high write latency"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db_instance.id
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_IOPS" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-IOPS"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = var.iops_alarm_threshold
  alarm_description   = "This alarm monitors for high IOPS"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  metric_query {
    id          = "e1"
    expression  = "m1+m2"
    label       = "Total IOPS"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "ReadIOPS"
      namespace   = "AWS/RDS"
      period      = 300
      stat        = "Maximum"

      dimensions = {
        DBInstanceIdentifier = aws_db_instance.db_instance.id
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "WriteIOPS"
      namespace   = "AWS/RDS"
      period      = 300
      stat        = "Maximum"

      dimensions = {
        DBInstanceIdentifier = aws_db_instance.db_instance.id
      }
    }
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_Throughput" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-Storage-Throughput"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = var.throughput_alarm_threshold
  alarm_description   = "This alarm monitors for high Storage throughput"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  metric_query {
    id          = "e1"
    expression  = "(m1+m2)/1000000"
    label       = "Storage throughput"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "ReadThroughput"
      namespace   = "AWS/RDS"
      period      = 300
      stat        = "Maximum"

      dimensions = {
        DBInstanceIdentifier = aws_db_instance.db_instance.id
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "WriteThroughput"
      namespace   = "AWS/RDS"
      period      = 300
      stat        = "Maximum"

      dimensions = {
        DBInstanceIdentifier = aws_db_instance.db_instance.id
      }
    }
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_DiskQueueDepth" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-DiskQueueDepth"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.queue_depth_alarm_threshold
  alarm_description   = "This alarm monitors for high Disk Queue Depth"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db_instance.id
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_dashboard" "dash" {
  dashboard_name = "${var.env}-${var.microservice_name}-DB"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "type" : "metric",
          "x" : 0,
          "y" : 0,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.db_instance.id, { "region" : "${var.region}" }]
            ],
            "region" : "${var.region}",
            "period" : 300,
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "cpu",
                  "value" : 80
                }
              ]
            }
          }
        },
        {
          "type" : "metric",
          "x" : 6,
          "y" : 0,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              [{ "expression" : "m1/1000000000", "label" : "FreeStorageSpace", "id" : "e1", "region" : "${var.region}" }],
              ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.db_instance.id, { "region" : "${var.region}", "id" : "m1", "visible" : false }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "period" : 300,
            "stat" : "Minimum",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "storage Gb",
                  "value" : var.storage_alarm_threshold / 1000000000
                }
              ]
            },
            "title" : "FreeStorageSpace",
            "yAxis" : {
              "left" : {
                "label" : "",
                "showUnits" : false
              }
            }
          }
        },
        {
          "type" : "metric",
          "x" : 12,
          "y" : 0,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              [{ "expression" : "m1/1000000000", "label" : "FreeableMemory", "id" : "e1", "region" : "${var.region}" }],
              ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", aws_db_instance.db_instance.id, { "region" : "${var.region}", "id" : "m1", "visible" : false }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Minimum",
            "period" : 300,
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "memory Gb",
                  "value" : 1
                }
              ]
            },
            "yAxis" : {
              "right" : {
                "showUnits" : false
              },
              "left" : {
                "showUnits" : false
              }
            },
            "title" : "FreeableMemory"
          }
        },
        {
          "type" : "metric",
          "x" : 18,
          "y" : 0,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", aws_db_instance.db_instance.id, { "region" : "${var.region}" }],
              ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", aws_db_instance.db_instance.id, { "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Maximum",
            "period" : 300
          }
        },
        {
          "type" : "metric",
          "x" : 0,
          "y" : 6,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              [{ "expression" : "m1+m2", "label" : "IOPS", "id" : "e1", "region" : "${var.region}" }],
              ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", aws_db_instance.db_instance.id, { "id" : "m1", "visible" : false, "region" : "${var.region}" }],
              [".", "WriteIOPS", ".", ".", { "id" : "m2", "visible" : false, "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Maximum",
            "period" : 300,
            "title" : "IOPS",
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            },
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "iops",
                  "value" : var.iops_alarm_threshold
                }
              ]
            }
          }
        },
        {
          "type" : "metric",
          "x" : 6,
          "y" : 6,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              [{ "expression" : "(m1+m2)/1000000", "label" : "Throughput", "id" : "e1" }],
              ["AWS/RDS", "WriteThroughput", "DBInstanceIdentifier", aws_db_instance.db_instance.id, { "visible" : false, "id" : "m1" }],
              [".", "ReadThroughput", ".", ".", { "visible" : false, "id" : "m2" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            },
            "stat" : "Maximum",
            "period" : 300,
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "Throughput - Mbps",
                  "value" : var.throughput_alarm_threshold
                }
              ]
            }
          }
        },
        {
          "type" : "metric",
          "x" : 12,
          "y" : 6,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "DiskQueueDepth", "DBInstanceIdentifier", aws_db_instance.db_instance.id, { "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "period" : 300,
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "queue_depth",
                  "value" : var.queue_depth_alarm_threshold
                }
              ]
            },
            "stat" : "Sum"
          }
        },
        {
          "type" : "metric",
          "x" : 18,
          "y" : 6,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.db_instance.id, { "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Sum",
            "period" : 300,
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "connections",
                  "value" : 100
                }
              ]
            }
          }
        }
      ]
    }
  )
}
