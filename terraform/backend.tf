terraform {
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
