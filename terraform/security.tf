resource "aws_security_group" "k8s_nodes" {
  name        = "k8s-node-sg"
  description = "Security group for all Kubernetes nodes"
  vpc_id      = aws_vpc.main.id

  # Allow all internal VPC traffic for seamless pod-to-pod and kubelet communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # Allow outbound internet access (via NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
