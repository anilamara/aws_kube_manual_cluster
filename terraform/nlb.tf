resource "aws_lb" "k8s_api" {
  name               = "k8s-api-nlb"
  internal           = true # Keeps API server off the public internet
  load_balancer_type = "network"
  subnets            = aws_subnet.private[*].id
}

resource "aws_lb_target_group" "k8s_api" {
  name        = "k8s-api-tg"
  port        = 6443
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

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

# Attach the 3 Master Nodes to the NLB Target Group
resource "aws_lb_target_group_attachment" "master_api" {
  count            = 3
  target_group_arn = aws_lb_target_group.k8s_api.arn
  target_id        = aws_instance.master[count.index].id
  port             = 6443
}
