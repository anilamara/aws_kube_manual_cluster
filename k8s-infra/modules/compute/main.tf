data "aws_ami" "rhel9" {
  filter {
    name   = "image-id"
    values = ["ami-0af7e19d7f4a36103"]
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

  ingress {
    description = "Allow SSH from Default VPC Jump Server"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"] # Ensure this matches your Default VPC CIDR
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
  instance_type          = "c7i-flex.large"
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
  target_id = aws_instance.master[count.index].private_ip
  port             = 6443
}

resource "aws_instance" "worker" {
  count                  = 2
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "c7i-flex.large"
  subnet_id              = var.private_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  key_name               = aws_key_pair.k8s_auth.key_name

  tags = {
    Name = "${var.environment}-k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}

# ---------------------------------------------------------
# Security Group for Kubernetes Master (Control Plane) Nodes
# ---------------------------------------------------------
resource "aws_security_group" "k8s_master_sg" {
  name        = "production-k8s-master-sg"
  description = "Allow required ports for Kubernetes control plane"
  vpc_id      = var.vpc_id

  # Kubernetes API Server (From Load Balancer, Jump Server, and Workers)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # etcd server client API (From other Master nodes)
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Kubelet API, kube-scheduler, kube-controller-manager
  ingress {
    from_port   = 10250
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Calico Networking (BGP, VXLAN, IP-in-IP) and pod-to-pod traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allows all protocols internally
    cidr_blocks = [var.vpc_cidr]
  }

  # SSH from Jump Server
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------
# Security Group for Kubernetes Worker Nodes
# ---------------------------------------------------------
resource "aws_security_group" "k8s_worker_sg" {
  name        = "production-k8s-worker-sg"
  description = "Allow required ports for Kubernetes worker nodes"
  vpc_id      = var.vpc_id

  # Kubelet API (From Control Plane)
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NodePort Services (Allows testing via Jump Server and external Load Balancers)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Calico Networking (BGP, VXLAN, IP-in-IP) and pod-to-pod traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # SSH from Jump Server
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
