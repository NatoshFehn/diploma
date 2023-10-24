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

• Для развертки инфраструктуры использован [Terraform](https://github.com/NatoshFehn/Diplom/blob/main/terraform.md).  
• Для установки сервисов использован Ansible.

## *[Сеть main-network](terraform/network.tf)*

    Внутренняя подсеть для сайта web-1 10.1.0.0/16 ru-central1-a
    Внутренняя подсеть для сайта web-2 10.2.0.0/16 ru-central1-b
    Внутренняя подсеть для сервисов Elasticsearch, Prometheus 10.3.0.0/16 ru-central1-c
    Публичная подсеть bastion host, Grafana, Kibana 10.4.0.0/16 ru-central1-c

  ## *[Группы](terraform/groups.tf)*

    Target Group - web-1, web-2 
    Backend Group = Target Group - web-1, web-2
    Security Groups для внутренней подсети, для балансировщика, bastion host, Grafana, Kibana 

---------
## Сайт



---------
## Мониторинг



---------
## Логи



---------
## Сеть



---------
## Резервное копирование
