# Fetch the latest Red Hat Enterprise Linux 9 AMI
data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["301981869874"] # Official Red Hat AWS Account ID

  filter {
    name   = "name"
    values = ["RHEL-9.0.0_HVM-*-x86_64-*-Hourly2-GP2"]
  }
}

# 3 Master Nodes
resource "aws_instance" "master" {
  count                  = 3
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  key_name               = var.ssh_key_name

  tags = {
    Name = "k8s-master-${count.index + 1}"
    Role = "control-plane"
  }
}

# Dedicated GP3 EBS Volumes for etcd
resource "aws_ebs_volume" "etcd" {
  count             = 3
  availability_zone = aws_instance.master[count.index].availability_zone
  size              = 20
  type              = "gp3"
  iops              = 3000
  throughput        = 125

  tags = {
    Name = "etcd-vol-${count.index + 1}"
  }
}

# Attach etcd volumes to Master nodes
resource "aws_volume_attachment" "etcd_attach" {
  count       = 3
  device_name = "/dev/sdf" # Will map to /dev/nvme1n1 on t3 instances
  volume_id   = aws_ebs_volume.etcd[count.index].id
  instance_id = aws_instance.master[count.index].id
}

# 2 Worker Nodes
resource "aws_instance" "worker" {
  count                  = 2
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.private[count.index].id # Placed in AZ 1 and AZ 2
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  key_name               = var.ssh_key_name

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }
}

# Output the NLB DNS name so you can use it in your kubeadm init command
output "apiserver_endpoint" {
  value = aws_lb.k8s_api.dns_name
}
