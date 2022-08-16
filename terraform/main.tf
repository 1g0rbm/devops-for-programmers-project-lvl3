resource "yandex_vpc_network" "network-project-3" {
  name = "network-project-3"
}

resource "yandex_vpc_subnet" "subnet-project-3" {
  name           = "subnet-project-3"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-project-3.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "vm-1" {
  name        = "web-prject-3-01"
  platform_id = "standard-v2"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd80o2eikcn22b229tsa"
      size     = 5
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-project-3.id
    ip_address = "192.168.10.8"
    nat        = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.pvt_key)}"
  }
}

resource "yandex_compute_instance" "vm-2" {
  name        = "web-prject-3-02"
  platform_id = "standard-v2"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd80o2eikcn22b229tsa"
      size     = 5
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.subnet-project-3.id
    ip_address = "192.168.10.9"
    nat        = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.pvt_key)}"
  }
}

resource "yandex_alb_target_group" "lb_target_group" {
  name = "target-group-project-3"

  target {
    subnet_id  = yandex_vpc_subnet.subnet-project-3.id
    ip_address = yandex_compute_instance.vm-1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.subnet-project-3.id
    ip_address = yandex_compute_instance.vm-2.network_interface.0.ip_address
  }
}

resource "yandex_alb_backend_group" "lb-backend-group" {
  name = "backend-group-project-3"

  http_backend {
    name             = "project-3-http-backend"
    weight           = 1
    port             = 3000
    target_group_ids = [yandex_alb_target_group.lb_target_group.id]
    load_balancing_config {
      panic_threshold = 50
    }
    healthcheck {
      timeout  = "1s"
      interval = "1s"
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "lb-router" {
  name = "project-3-http-router"
}

resource "yandex_alb_virtual_host" "lb-virtual-host" {
  name           = "project-3-virtual-host"
  http_router_id = yandex_alb_http_router.lb-router.id
  route {
    name = "project-3"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.lb-backend-group.id
        timeout          = "3s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "lb-1" {
  name       = "project-3-lb"
  network_id = yandex_vpc_network.network-project-3.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-project-3.id
    }
  }

  listener {
    name = "project-3-listener-http"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.lb-router.id
      }
    }
  }

  listener {
    name = "project-3-listener-https"
    endpoint {
      ports = [443]
      address {
        external_ipv4_address {
        }
      }
    }

    tls {
      default_handler {
        certificate_ids = ["fpqcihlrj0o9seas10ja"]

        http_handler {
          http_router_id = yandex_alb_http_router.lb-router.id
        }
      }
    }
  }
}

resource "yandex_dns_zone" "zone1" {
  name   = "project-3-dns-zone"
  zone   = "botgate.ru."
  public = true
}

resource "yandex_dns_recordset" "rs1" {
  zone_id = yandex_dns_zone.zone1.id
  name    = "botgate.ru."
  type    = "A"
  ttl     = 200
  data    = [yandex_alb_load_balancer.lb-1.listener[0].endpoint[0].address[0].external_ipv4_address[0].address]
}

resource "yandex_dns_recordset" "rs2" {
  zone_id = yandex_dns_zone.zone1.id
  name    = "_acme-challenge.botgate.ru."
  type    = "CNAME"
  ttl     = 600
  data    = ["fpqcihlrj0o9seas10ja.cm.yandexcloud.net."]
}

resource "yandex_dns_recordset" "rs3" {
  zone_id = yandex_dns_zone.zone1.id
  name    = "_acme-challenge.www.botgate.ru."
  type    = "CNAME"
  ttl     = 600
  data    = ["fpqcihlrj0o9seas10ja.cm.yandexcloud.net."]
}

output "webservers" {
  value = [
    yandex_compute_instance.vm-1,
    yandex_compute_instance.vm-2
  ]
  sensitive = true
}