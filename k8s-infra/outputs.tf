output "k8s_api_endpoint" {
  value       = module.loadbalancer.nlb_dns_name
  description = "Use this for the kubeadm init --control-plane-endpoint flag"
}
