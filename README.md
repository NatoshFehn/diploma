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

• Для развертки инфраструктуры использован [Terraform](https://github.com/NatoshFehn/diploma/blob/main/terraform).  
• Для установки сервисов использован [Ansible](https://github.com/NatoshFehn/diploma/blob/main/ansible).

### Сеть main-network

    Внутренняя подсеть для сайта web-1 10.1.0.0/16 ru-central1-a
    Внутренняя подсеть для сайта web-2 10.2.0.0/16 ru-central1-b
    Внутренняя подсеть для сервисов Elasticsearch, Prometheus 10.3.0.0/16 ru-central1-c
    Публичная подсеть bastion host, Grafana, Kibana 10.4.0.0/16 ru-central1-c

### Группы

    Target Group - web-1, web-2 
    Backend Group = Target Group - web-1, web-2
    Security Groups для внутренней подсети, для балансировщика, bastion host, Grafana, Kibana 

### Инстансы 
[web-1, web-2](https://github.com/NatoshFehn/diploma/blob/main/terraform/web-servers.tf) |
[bastion](https://github.com/NatoshFehn/diploma/blob/main/terraform/bastion.tf) |
[load-balancer](https://github.com/NatoshFehn/diploma/blob/main/terraform/load-balancer.tf) |
[router](https://github.com/NatoshFehn/diploma/blob/main/terraform/router.tf) |
[prometheus](https://github.com/NatoshFehn/diploma/blob/main/terraform/prometheus.tf) |
[grafana](https://github.com/NatoshFehn/diploma/blob/main/terraform/grafana.tf) |
[elasticsearch](https://github.com/NatoshFehn/diploma/blob/main/terraform/elasticsearch.tf) |
[kibana](https://github.com/NatoshFehn/diploma/blob/main/terraform/kibana.tf)

![Снимок2](https://github.com/NatoshFehn/diploma/blob/main/img/Снимок2.JPG)

---------
## Сайт

### <a href = "http://158.160.130.200/" target="_blank">http://158.160.130.200/</a>
![сайт](<https://github.com/NatoshFehn/diploma/blob/main/img/сайт.JPG>)

Создайно две ВМ в разных зонах посредством [Terraform](terraform): [web-servers.tf](https://github.com/NatoshFehn/diploma/blob/main/terraform/web-servers.tf). 
Поскольку это похожие ресурсы, то  в переменных [variables.tf](https://github.com/NatoshFehn/diploma/blob/main/terraform/variables.tf) создан map, ключом в котором является имя сервера, а значения  содержет зону, подсеть, IP-адреc.

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

После этого, чтобы не описывать несколько похожих ресурсов, в одном ресурсе `yandex_compute_instance` [web-servers.tf]([terraform](https://github.com/NatoshFehn/diploma/blob/main/terraform)/web-servers.tf) использован цикл `for_each`.

id образа вынесен в переменную [variables.tf]([terraform](https://github.com/NatoshFehn/diploma/blob/main/terraform)/variables.tf) и использован конкретный id - fd81ojtctf7kjqa3au3i - Debian 11.

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

C помощью Ansible, с использованием [web-playbook.yml](ansible/web-playbook.yml), на веб-сервера установлены (через бастион):
- nginx 1.18.0 с использованием роли [geerlingguy.nginx](ansible/roles/geerlingguy.nginx)
- [node_exporter](ansible/roles/node_exporter)
- [nginx-exporter](ansible/roles/nginx-exporter) 
- [filebeat](ansible/roles/filebeat)

![Снимок3](<https://github.com/NatoshFehn/diploma/blob/main/img/Снимок3.JPG>)

Использован  файл для сайта [index.html](https://github.com/NatoshFehn/diploma/blob/main/ansible/roles/geerlingguy.nginx/files/index.html), сгенерирован c подстановкой ip адресов автоматически из terraform, c  помощью ресурса local_file [terraform/local_files.tf](https://github.com/NatoshFehn/diploma/blob/main/terraform/local_files.tf) и шаблона  [index.tpl](terraform/templates/index.tpl).

Созданы Target Group, Backend Group [groups.tf](https://github.com/NatoshFehn/Diplom/blob/main/terraform/groups.tf).

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

![Снимок4](<https://github.com/NatoshFehn/diploma/blob/main/img/Снимок4.JPG>)

![Снимок5](<https://github.com/NatoshFehn/diploma/blob/main/img/Снимок5.JPG>)

Создан HTTP router [router.tf](https://github.com/NatoshFehn/diploma/blob/main/terraform/router.tf).

Создан Application load balancer [load-balancer.tf](https://github.com/NatoshFehn/diploma/blob/main/terraform/load-balancer.tf).

![Снимок6](<https://github.com/NatoshFehn/diploma/blob/main/img/Снимок6.JPG>)

Сайт открывается с публичного IP балансера
### <a href = "http://158.160.130.200/" target="_blank">http://158.160.130.200/</a>

Сайт протестирован 'curl -v 158.160.130.200:80'

<details>

*<summary>curl -v 158.160.130.200:80</summary>*

```GO
*   Trying 158.160.130.200:80...
* Connected to 158.160.130.200 (158.160.130.200) port 80 (#0)
> GET / HTTP/1.1
> Host: 158.160.130.200
> User-Agent: curl/7.74.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< server: ycalb
< date: Thu, 26 Oct 2023 10:03:48 GMT
< content-type: text/html
< content-length: 2238
< last-modified: Thu, 26 Oct 2023 09:19:56 GMT
< etag: "653a2f3c-8be"
< accept-ranges: bytes
< 
<!doctype html>
<html>
<head>
	<meta http-equiv="Content-type" content="text/html; charset=utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=Edge">
	<title>sys-diplom-martynova</title>

	<style type="text/css">
		body {
			font-family: 'Lato', sans-serif;
			font-weight: 400;
			font-size: 16px;
			line-height: 1.7;
			color: #eee;
		}

		.header {
			height: 100vh;
			background-image: 
			url('https://phonoteka.org/uploads/posts/2021-04/1618468797_11-phonoteka_org-p-dlinnii-fon-13.jpg');
			
		background-size: cover;
			background-position: top;
			position: relative;

			clip-path: polygon(0 0, 100% 0, 100% 75vh, 0 100%);
		}

		.brand-box {
			position: absolute;
			top: 40px;
			left: 40px;
		}

		.brand { font-size: 20px; }

		.text-box {
			position: absolute;
			top: 50%;
			left: 50%;
			transform: translate(-50%, -50%);
			text-align: center;
		}

		.heading-primary {
			color: #fff;
			text-transform: uppercase;

			backface-visibility: hidden;
			margin-bottom: 30px;
		}

		.heading-primary-main {
			display: block;
			font-size: 26px;
			font-weight: 400;
			letter-spacing: 5px;
		}

		.heading-primary-sub {
			display: block;
			font-size: 18px;
			font-weight: 700;
			letter-spacing: 7.4px;
		}

		.btn:link,
		.btn:visited {
			text-transform: uppercase;
			text-decoration: none;
			padding: 10px 20px;
			display: inline-block;
			border-radius: 100px;
			transition: all .2s;
			position: relative;
		}

		.btn:hover {
			transform: translateY(-3px);
			box-shadow: 0 10px 20px rgba(0, 0, 0, 0.2);
		}

		.btn:active {
			transform: translateY(-1px);
			box-shadow: 0 5px 10px rgba(0, 0, 0, 0.2);
		}

		.btn-white {
			background-color: #fff;
			color: #777;
			font-size: 14px;
		}

	</style>
</head>
<body>

<header class="header">

	<div class="text-box">
		<h1 class="heading-primary">
		<span class="heading-primary-main">Hello, Netology! (c)Natalya Martynova</span>
		</h1>
		<a href="http://51.250.42.23:3000/" target="_blank" class="btn btn-white btn-animated">Grafana</a>
		&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
		<a  href="http://51.250.40.82:5601" target="_blank" class="btn btn-white btn-animated">Kibana</a>
	</br>	</br>

	</span></h1>
	</div>
	</header>

</body>
</html>
* Connection #0 to host 158.160.130.200 left intact
```
</details>

---------
## Мониторинг



---------
## Логи



---------
## Сеть

Развернута VPC.

[terraform/network.tf](<https://github.com/NatoshFehn/diploma/blob/main/terraform/network.tf)

<details>

*<summary>network.tf</summary>*

```GO
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
```
</details>

![Снимок7](<https://github.com/NatoshFehn/diploma/blob/main/img/Снимок7.JPG)

Сервера web-1, web-2, Prometheus, Elasticsearch помещены в приватные подсети. 

Сервера Grafana, Kibana, application load balancer, bastion host определены в публичную подсеть.

Настроена Security Groups [groups.tf](https://github.com/NatoshFehn/diploma/blob/main/terraform/groups.tf) соответствующих сервисов на входящий трафик только к нужным портам.

Настроена ВМ [bastion.tf](https://github.com/NatoshFehn/diploma/blob/main/terraform/bastion.tf) с публичным адресом 51.250.41.17, в которой  открыт только один порт — ssh. 

Настроены все security groups на разрешение входящего ssh из этой security group. 
Эта вм  реализует концепцию bastion host. 
Можно  подключаться по ssh ко всем хостам через этот хост.

Пример - доступ через бастион к web-1:

```bash
ssh -i ~/.ssh/id_rsa -J 51.250.41.17 martynova@10.1.0.10

```
![Снимок8](https://github.com/NatoshFehn/diploma/blob/main/img/Снимок8.JPG)

В [hosts](https://github.com/NatoshFehn/diploma/blob/main/ansible/hosts) ansible указано специальное правило подключения к хостам через bastion host

<details>

*<summary>правило подключения к хостам через bastion host</summary>*

```GO

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q 51.250.44.226"'

```
</details>

Настроена таблица маршрутизации для доступа из машин в локальной сети к интеренет через бастион [network.tf](https://github.com/NatoshFehn/diploma/blob/main/terraform/network.tf).

<details>

*<summary>таблица маршрутизации</summary>*

```GO
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
```
</details>

![Снимок9](https://github.com/NatoshFehn/diploma/blob/main/img/Снимок9.JPG)

---------
## Резервное копирование
