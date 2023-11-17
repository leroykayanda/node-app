resource "aws_s3_bucket" "alb_access_logs" {
  count         = var.create_elb == "yes" ? 1 : 0
  bucket        = "${var.env}-${var.company_name}-${var.service_name}-alb-access-logs"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_alb_access_logs" {
  count  = var.create_elb == "yes" ? 1 : 0
  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    expiration {
      days = 180
    }
    status = "Enabled"
    id     = "access-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt_access_log_bucket" {
  count  = var.create_elb == "yes" ? 1 : 0
  bucket = aws_s3_bucket.alb_access_logs[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_logs_bucket" {
  count                   = var.create_elb == "yes" ? 1 : 0
  bucket                  = aws_s3_bucket.alb_access_logs[0].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "access_log_bucket_policy" {
  count  = var.create_elb == "yes" ? 1 : 0
  bucket = aws_s3_bucket.alb_access_logs[0].id
  policy = data.aws_iam_policy_document.s3_bucket_lb_write[0].json
}

module "alb" {
  #https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/6.4.0
  count   = var.create_elb == "yes" ? 1 : 0
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name         = "${var.env}-${var.service_name}"
  internal     = var.internal
  idle_timeout = var.idle_timeout

  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  subnets         = var.alb_subnets
  security_groups = [aws_security_group.alb_sg[0].id]

  access_logs = {
    bucket  = aws_s3_bucket.alb_access_logs[0].bucket
    prefix  = "logs"
    enabled = true
  }

  target_groups = [
    {
      name_prefix          = "${var.env}-"
      backend_protocol     = "HTTP"
      backend_port         = var.container_port
      target_type          = "ip"
      deregistration_delay = var.deregistration_delay
      protocol_version     = "HTTP1"

      health_check = {
        enabled             = true
        interval            = 30
        path                = var.health_check_path
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.certificate_arn
      target_group_index = 0
      ssl_policy         = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
    }
  ]

  tags = {
    Environment = var.env
    waf         = var.waf
    Team        = var.team
  }
}
