locals {
  my_ip_cidr = "147.45.137.114/32"
}

resource "yandex_vpc_network" "k8s_network" {
  name = "k8s-network"
  description = "k8s network"
}

resource "yandex_vpc_subnet" "k8s_subnet" {
  name = "k8s-subnet"
  description = "k8s subnet"
  v4_cidr_blocks = ["10.2.0.0/24"]
  zone = "ru-central1-a"
  network_id = "${yandex_vpc_network.k8s_network.id}"
}

resource "yandex_vpc_security_group" "k8s-public-services" {
  name        = "k8s-public-services"
  description = "Правила группы разрешают подключение к сервисам из интернета"
  network_id  = yandex_vpc_network.k8s_network.id
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера Managed Service for Kubernetes и сервисов балансировщика."
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие под-под и сервис-сервис. Укажите подсети вашего кластера Managed Service for Kubernetes и сервисов."
    v4_cidr_blocks    = concat(yandex_vpc_subnet.k8s_subnet.v4_cidr_blocks)
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ICMP"
    description       = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
    v4_cidr_blocks    = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавьте или измените порты на нужные вам."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 30000
    to_port           = 32767
  }
  egress {
    protocol          = "ANY"
    description       = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Yandex Object Storage, Docker Hub и т. д."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}

resource "yandex_vpc_security_group" "k8s-master-api" {
  name        = "k8s-master-api"
  description = "Kubernetes master API + internal cluster traffic"
  network_id  = yandex_vpc_network.k8s_network.id

  # --- Доступ к Kubernetes API (kubectl) ТОЛЬКО с твоего IP ---
  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API access from my IP"
    v4_cidr_blocks = [local.my_ip_cidr]
    from_port      = 0
    to_port        = 65535
  }

  # --- ВНУТРЕННЕЕ взаимодействие master <-> nodes ---
  # Нужно, чтобы ноды могли присоединиться к кластеру
  ingress {
    protocol       = "ANY"
    description    = "Internal traffic from cluster subnet (nodes, pods)"
    v4_cidr_blocks = yandex_vpc_subnet.k8s_subnet.v4_cidr_blocks
    from_port      = 0
    to_port        = 65535
  }

  # --- Исходящий трафик (обязательно) ---
  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}