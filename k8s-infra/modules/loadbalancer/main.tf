resource "aws_lb" "k8s_api" {
  name               = "${var.environment}-k8s-api-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids
}

resource "aws_lb_target_group" "k8s_api" {
  name        = "production-k8s-api-tg-ip"
  port        = 6443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
 
  lifecycle {
    create_before_destroy = true
  }

  health_check {
    protocol            = "TCP"
    port                = "6443"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
  }
}

resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn = aws_lb.k8s_api.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_api.arn
  }
}
