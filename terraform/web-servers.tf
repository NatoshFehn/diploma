resource "yandex_compute_instance" "web-servers" {
  for_each    = local.web-servers
  hostname    = each.key
  name        = each.key
  zone        = each.value.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      type     = "network-ssd"
      size     = "16"    
      }
  }

  network_interface {
    subnet_id  = each.value.subnet_id
    security_group_ids = [yandex_vpc_security_group.private-sg.id]
    ip_address         = each.value.ip_address
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }



}
