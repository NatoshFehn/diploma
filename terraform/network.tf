### Сеть ###

resource "yandex_vpc_network" "main-network" {
  name        = "main-network"
  description = "network for diplom"
}

### Настройка Nat-шлюза и статический маршрут через бастион для внутренней сети ###

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "test-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  network_id = yandex_vpc_network.main-network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}


### Внутренняя подсеть для сайта 1 ###

resource "yandex_vpc_subnet" "private-subnet-1" {
  name           = "private-subnet-1"
  description    = "subnet for web-1"
  v4_cidr_blocks = ["10.1.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main-network.id
#  route_table_id = yandex_vpc_route_table.route_table.id

}

### Внутренняя подсеть для сайта 2 ###

resource "yandex_vpc_subnet" "private-subnet-2" {
  name           = "private-subnet-2"
  description    = "subnet for web-2"
  v4_cidr_blocks = ["10.2.0.0/16"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main-network.id
  route_table_id = yandex_vpc_route_table.route_table.id
}

### Внутренняя подсеть для сервисов ###

resource "yandex_vpc_subnet" "private-subnet-3" {
  name           = "private-subnet-3"
  description    = "subnet for services"
  v4_cidr_blocks = ["10.3.0.0/16"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.main-network.id
  route_table_id = yandex_vpc_route_table.route_table.id
}

### Публичная подсеть для бастиона, графаны, кибаны ###

resource "yandex_vpc_subnet" "public-subnet" {
  name           = "public-subnet"
  description    = "subnet for bastion"
  v4_cidr_blocks = ["10.4.0.0/16"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.main-network.id
}
