# Application Load Balancer
resource "aws_lb" "uptime_kuma" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "uptime_kuma" {
  name        = "${var.project_name}-tg"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# HTTP Listener
resource "aws_lb_listener" "uptime_kuma" {
  load_balancer_arn = aws_lb.uptime_kuma.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.uptime_kuma.arn
  }
}

# HTTPS Listener (optional - requires SSL certificate)
# Uncomment and configure if you have an ACM certificate
# resource "aws_lb_listener" "uptime_kuma_https" {
#   load_balancer_arn = aws_lb.uptime_kuma.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = var.certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.uptime_kuma.arn
#   }
# }

# HTTP to HTTPS redirect (optional)
# Uncomment if using HTTPS
# resource "aws_lb_listener" "uptime_kuma_http_redirect" {
#   load_balancer_arn = aws_lb.uptime_kuma.arn
#   port              = "80"
#   protocol          = "HTTP"
#
#   default_action {
#     type = "redirect"
#
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }
