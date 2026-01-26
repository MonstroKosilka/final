terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    bucket = "my-tf-state-bucket-monstrokosilka"
    key    = "k8s-single/terraform.tfstate"

    # Для Object Storage (Yandex) настройки:
    region   = "ru-central1"
    endpoint = "https://storage.yandexcloud.net"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}

provider "yandex" {
  zone = "ru-central1-a"
}