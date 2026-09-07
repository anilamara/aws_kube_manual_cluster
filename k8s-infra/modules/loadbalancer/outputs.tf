output "target_group_arn" { value = aws_lb_target_group.k8s_api.arn }
output "nlb_dns_name" { value = aws_lb.k8s_api.dns_name }
