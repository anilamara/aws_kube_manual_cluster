output "k8s_api_endpoint" {
  value       = module.loadbalancer.nlb_dns_name
  description = "Use this for the kubeadm init --control-plane-endpoint flag"
}

output "master_private_ips" {
  value = module.compute.master_private_ips
}

output "worker_private_ips" {
  value = module.compute.worker_private_ips
}
