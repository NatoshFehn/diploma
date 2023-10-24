# generate inventory file for Ansible
resource "local_file" "hosts" {
  content = templatefile("${var.path_terraform}/templates/hosts.tpl",
    {
      web_ip = values(yandex_compute_instance.web-servers)[*].network_interface[0].ip_address
      prometheus_ip = yandex_compute_instance.prometheus.network_interface[0].ip_address
      grafana_ip = yandex_compute_instance.grafana.network_interface[0].ip_address
      elasticsearch_ip = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
      kibana_ip = yandex_compute_instance.kibana.network_interface[0].ip_address
      bastion_ip = yandex_compute_instance.bastion.network_interface.0.nat_ip_address

    }
  )
  filename = "${var.path_ansible}/hosts"
}

# generate index.html for nginx
resource "local_file" "nginx" {
  content = templatefile("${var.path_terraform}/templates/index.tpl",
    {
      grafana_ip = yandex_compute_instance.grafana.network_interface[0].nat_ip_address
      kibana_ip = yandex_compute_instance.kibana.network_interface[0].nat_ip_address

    }
  )
  filename = "${var.path_ansible}/roles/geerlingguy.nginx/files/index.html"
}
