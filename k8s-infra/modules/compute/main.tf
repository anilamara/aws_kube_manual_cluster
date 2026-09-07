data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["301981869874"]
  filter {
    name   = "name"
    values = ["RHEL-9*_HVM-*-x86_64-*-Hourly2-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "k8s_auth" {
  key_name   = "${var.environment}-k8s-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "k8s_nodes" {
  name        = "${var.environment}-k8s-nodes-sg"
  description = "Allow internal VPC traffic and internet egress"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "master" {
  count                  = 3
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t3.large"
  subnet_id              = var.private_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  key_name               = aws_key_pair.k8s_auth.key_name

  tags = {
    Name = "${var.environment}-k8s-master-${count.index + 1}"
    Role = "control-plane"
  }
}

resource "aws_ebs_volume" "etcd" {
  count             = 3
  availability_zone = aws_instance.master[count.index].availability_zone
  size              = 20
  type              = "gp3"
  iops              = 3000

  tags = { Name = "${var.environment}-etcd-vol-${count.index + 1}" }
}

resource "aws_volume_attachment" "etcd_attach" {
  count       = 3
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.etcd[count.index].id
  instance_id = aws_instance.master[count.index].id
}

resource "aws_lb_target_group_attachment" "master_api" {
  count            = 3
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.master[count.index].id
  port             = 6443
}

resource "aws_instance" "worker" {
  count                  = 2
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t3.large"
  subnet_id              = var.private_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  key_name               = aws_key_pair.k8s_auth.key_name

  tags = {
    Name = "${var.environment}-k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}
