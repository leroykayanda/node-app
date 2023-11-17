#ECS IAM role
resource "aws_iam_role" "prometheus_execution_role" {
  name = "${var.env}-${var.service}-Task-Execution-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_policy_attachment_AmazonECSTaskExecutionRolePolicy" {
  role       = aws_iam_role.prometheus_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "prometheus_policy" {
  name = "prometheus-service-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "elasticfilesystem:ClientRootAccess"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_policy_attachment" {
  role       = aws_iam_role.prometheus_execution_role.name
  policy_arn = aws_iam_policy.prometheus_policy.arn
}

#prometheus task SG
resource "aws_security_group" "prometheus_task_sg" {
  name        = "${var.env}-prometheus-Task-SG"
  description = "Prometheus Task traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "ALB health check traffic"
    from_port   = var.prometheus_container_port
    to_port     = var.prometheus_container_port
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
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

  tags = {
    Name = "${var.env}-prometheus-Task-SG"
  }
}

#db SG
resource "aws_security_group" "db_sg" {
  name        = "${var.env}-${var.service}-DB-SG"
  description = "DB traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.service}-DB-SG"
  }
}

variable "fargate_cpu" {
  type    = number
  default = 1024
}

variable "fargate_mem" {
  type    = number
  default = 2048
}

#app security group
resource "aws_security_group" "app_sg" {
  name        = "${var.env}-${var.service}-task-sg"
  description = "${var.env}-${var.service}-task-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "ALB health check traffic"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
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
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "redis"
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "DB"
  }

  tags = {
    Name = "${var.env}-${var.service}-task-sg"
  }
}
