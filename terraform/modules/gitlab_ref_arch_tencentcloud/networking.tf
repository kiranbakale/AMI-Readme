terraform {
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "1.56.2"
    }
  }
}

provider "tencentcloud" {
  region = "ap-shanghai"
}

data "tencentcloud_instance_types" "instance_type" {
  cpu_core_count = var.default_cpu_core_count
  memory_size    = var.default_memory_size
}

data "tencentcloud_availability_zones" "zones_ds" {
}

resource "tencentcloud_vpc" "vpc" {
  name       = var.vpc_name
  cidr_block = var.vpc_cidr
}

resource "tencentcloud_subnet" "default" {
  name              = var.subnet_name
  vpc_id            = tencentcloud_vpc.vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = data.tencentcloud_availability_zones.zones_ds.zones.0.name
}

resource "tencentcloud_security_group" "gitlab_external_ssh" {
  name        = "${var.prefix}-external-ssh-networking"
  description = "${var.prefix}-external-ssh-networking group"
}
