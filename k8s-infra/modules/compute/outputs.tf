output "master_private_ips" { value = aws_instance.master[*].private_ip }
output "worker_private_ips" { value = aws_instance.worker[*].private_ip }
