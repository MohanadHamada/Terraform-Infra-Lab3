# Load Balancer Module - Creates Application Load Balancer with target groups

# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = var.name
    Type = var.internal ? "private" : "public"
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.name}-tg"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Load balancing algorithm
  load_balancing_algorithm_type = "round_robin"

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  # Stickiness configuration (disabled for better load distribution)
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  # Connection draining
  deregistration_delay = 300

  tags = {
    Name = "${var.name}-target-group"
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "main" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.target_instance_ids[count.index]
  port             = var.target_port
}

# Load Balancer Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Optional HTTPS Listener (commented out - can be enabled with SSL certificate)
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = var.ssl_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.main.arn
#   }
# }