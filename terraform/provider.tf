variable "pvt_key" {
  type      = string
  sensitive = true
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  required_version = ">= 0.13"

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "1g0rbm-terraform-storage"
    region     = "ru-central1"
    key        = "terraform-backend/state.tfstate"
    # access_key
    # secret_key

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

variable "token" {
  type      = string
  sensitive = true
}
variable "cloud_id" {
  type      = string
  sensitive = true
}
variable "folder_id" {
  type      = string
  sensitive = true
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}
