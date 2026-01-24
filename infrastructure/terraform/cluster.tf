locals {
  folder_id = "b1ggvdkuirasr65l8a9f"
}

resource "yandex_kubernetes_cluster" "k8s-single" {
  name = "k8s-single"
  network_id = yandex_vpc_network.k8s_network.id
  master {
    public_ip = true

    master_location {
      zone = yandex_vpc_subnet.k8s_subnet.zone
      subnet_id = yandex_vpc_subnet.k8s_subnet.id
    }
    security_group_ids = [yandex_vpc_security_group.k8s-master-api.id]
  }

  service_account_id      = yandex_iam_service_account.myaccount.id
  node_service_account_id = yandex_iam_service_account.myaccount.id
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_member.vpc-public-admin,
    yandex_resourcemanager_folder_iam_member.images-puller,
    yandex_resourcemanager_folder_iam_member.encrypterDecrypter,
    yandex_resourcemanager_folder_iam_member.load-balancer-admin
  ]
  kms_provider {
    key_id = yandex_kms_symmetric_key.kms-key.id
  }
}

resource "yandex_kubernetes_node_group" "ng-default" {
  cluster_id = yandex_kubernetes_cluster.k8s-single.id
  name       = "ng-default"

  # Где размещать узлы
  allocation_policy {
    location {
      zone = yandex_vpc_subnet.k8s_subnet.zone
    }
  }

  # Сколько узлов
  scale_policy {
    fixed_scale {
      size = 1  
    }
  }

  # Какой инстанс и параметры
  instance_template {
    platform_id = "standard-v2"

    resources {
      cores  = 2
      memory = 4
    }

    boot_disk {
      type = "network-ssd"
      size = 30
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.k8s_subnet.id]
      nat        = true  
      security_group_ids = [
        yandex_vpc_security_group.k8s-public-services.id
      ]
    }

  }

  depends_on = [
    yandex_kubernetes_cluster.k8s-single
  ]
}


resource "yandex_iam_service_account" "myaccount" {
  name        = "myaccount"
  description = "Service account for the single Kubernetes cluster"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  # Сервисному аккаунту назначается роль "k8s.clusters.agent".
  folder_id = local.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
  # Сервисному аккаунту назначается роль "vpc.publicAdmin".
  folder_id = local.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  # Сервисному аккаунту назначается роль "container-registry.images.puller".
  folder_id = local.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "encrypterDecrypter" {
  # Сервисному аккаунту назначается роль "kms.keys.encrypterDecrypter".
  folder_id = local.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "load-balancer-admin" {
  # Сервисному аккаунту назначается роль "load-balancer.admin".
  folder_id = local.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_kms_symmetric_key" "kms-key" {
  # Ключ Yandex Key Management Service для шифрования важной информации, такой как пароли, OAuth-токены и SSH-ключи.
  name              = "kms-key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" # 1 год.
}