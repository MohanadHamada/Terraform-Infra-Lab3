resource "aws_lb" "elb" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = [var.sg_id]
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/"
    port = "80"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.target_instance_ids[count.index]
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

data "aws_subnet" "selected" {
  id = length(var.subnets) > 0 ? var.subnets[0] : ""
}

data "aws_vpc" "selected" {
  id = data.aws_subnet.selected.vpc_id
}
