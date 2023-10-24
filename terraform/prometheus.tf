resource "yandex_compute_instance" "prometheus" {
  name        = "prometheus"
  hostname    = "prometheus"
  zone        = "ru-central1-c"

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
    subnet_id  = yandex_vpc_subnet.private-subnet-3.id
    security_group_ids = [yandex_vpc_security_group.private-sg.id]
    ip_address         = "10.3.0.10"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }

  
}
