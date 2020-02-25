output "deployer_elb_hostname" {
  value = element(concat(kubernetes_service.dotscience_deployer[*].load_balancer_ingress[0].hostname, list("")), 0)
}

output "deployer_elb_ip" {
  value = element(concat(kubernetes_service.dotscience_deployer[*].load_balancer_ingress[0].ip, list("")), 0)
}