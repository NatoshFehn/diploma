output "external_ip_addres_load_balancer_piblic_ip" {
  value = yandex_alb_load_balancer.load-balancer.listener.0.endpoint.0.address.0.external_ipv4_address
}

output "bastion_piblic_ip" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}
output "kibana_piblic_ip" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}
output "grafana_piblic_ip" {
  value = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
}

output "web_private_ip" {
  value = values(yandex_compute_instance.web-servers)[*].network_interface[0].ip_address
}


output "prometheus_private_ip" {
      value = yandex_compute_instance.prometheus.network_interface[0].ip_address
}

output "grafana_ip" {
      value = yandex_compute_instance.grafana.network_interface[0].ip_address
}

output "kibana_ip" {
      value = yandex_compute_instance.kibana.network_interface[0].ip_address
}

