#  Дипломная работа по профессии «Системный администратор» - Наталья Мартынова

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
* [Сайт](#Сайт)
* [Мониторинг](#Мониторинг)
* [Логи](#Логи)
* [Сеть](#Сеть)
* [Резервное копированиее](#Резервное-копирование)


---------
## Задача

Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/).

---------
## Инфраструктура

• Для развертки инфраструктуры использован [Terraform](https://github.com/NatoshFehn/Diplom/blob/main/terraform).  
• Для установки сервисов использован [Ansible] (https://github.com/NatoshFehn/Diplom/blob/main/ansible).

### Сеть main-network

    Внутренняя подсеть для сайта web-1 10.1.0.0/16 ru-central1-a
    Внутренняя подсеть для сайта web-2 10.2.0.0/16 ru-central1-b
    Внутренняя подсеть для сервисов Elasticsearch, Prometheus 10.3.0.0/16 ru-central1-c
    Публичная подсеть bastion host, Grafana, Kibana 10.4.0.0/16 ru-central1-c

### Группы

    Target Group - web-1, web-2 
    Backend Group = Target Group - web-1, web-2
    Security Groups для внутренней подсети, для балансировщика, bastion host, Grafana, Kibana 

---------
## Сайт

Создайно две ВМ в разных зонах посредством [Terraform](terraform): [web-servers.tf](terraform/web-servers.tf). 
Поскольку это похожие ресурсы, то  в переменных [variables.tf](terraform/variables.tf)  создан map, ключом в котором является имя сервера, а значения  содержет зону, подсеть, IP-адреc.

<details>

*<summary>map</summary>*

``` GO
locals {
  web-servers = {
   "web-1" = { zone = "ru-central1-a", subnet_id  = yandex_vpc_subnet.private-subnet-1.id, ip_address = "10.1.0.10" },
   "web-2" = { zone = "ru-central1-b", subnet_id  = yandex_vpc_subnet.private-subnet-2.id, ip_address = "10.2.0.10" }
 }
}
```
</details>

После этого, чтобы не описывать несколько похожих ресурсов, в одном ресурсе `yandex_compute_instance` [web-servers.tf](terraform/web-servers.tf) использован цикл `for_each`.

id образа вынесен в переменную [variables.tf](terraform/variables.tf) и использован конкретный id - fd81ojtctf7kjqa3au3i - Debian 11.

<details>

*<summary>variables.tf</summary>*

``` GO
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
```
</details>

В результате созданы веб-сервера. ОС и содержимое ВМ идентично.

    web-1 10.1.0.10 ru-central1-a
    web-2 10.2.0.10 ru-central1-b

C помощью Ansible, с использованием [web-playbook.yml](ansible/web-playbook.yml), на веб-сервера установлены:
- nginx 1.18.0 с использованием роли [geerlingguy.nginx](ansible/roles/geerlingguy.nginx)
- [node_exporter](ansible/roles/node_exporter)
- [nginx-exporter](ansible/roles/nginx-exporter) 
- [filebeat](ansible/roles/filebeat)

Использован  файл для сайта [index.html](ansible/roles/geerlingguy.nginx/files/index.html), сгенерирован c подстановкой ip адресов автоматически из terraform, c  помощью ресурса local_file [terraform/local_files.tf](terraform/local_files.tf) и шаблона  [index.tpl](terraform/templates/index.tpl).

Созданы Target Group, Backend Group [groups.tf](terraform/groups.tf).

Так как создание nginx-серверов реализовано через цикл for each, то для автоматического добавления всех имеющихся nginx-серверов к балансировке использован мета-аргумент dynamic.

<details>

*<summary>мета-аргумент dynamic</summary>*

```GO
resource "yandex_alb_target_group" "tg-group" {
  name = "tg-group"
  
  dynamic "target" {
    for_each = local.web-servers
    content {
      ip_address = target.value.ip_address
      subnet_id  = target.value.subnet_id

    }
  }
  
}
```
</details>

Создан HTTP router [router.tf](terraform/router.tf).

Создан Application load balancer [load-balancer.tf](terraform/load-balancer.tf).

Сайт открывается с публичного IP балансера
### <a href = "http://158.160.130.200/" target="_blank">http://158.160.130.200/</a>

---------
## Мониторинг



---------
## Логи



---------
## Сеть



---------
## Резервное копирование
