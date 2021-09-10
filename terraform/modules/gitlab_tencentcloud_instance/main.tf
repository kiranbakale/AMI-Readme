terraform {
  required_version = ">= 0.14"

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

data "tencentcloud_images" "ubuntu" {
  image_type = ["PUBLIC_IMAGE"]
  os_name    = "Ubuntu Server 18.04"
}

data "tencentcloud_availability_zones" "default" {
}


resource "tencentcloud_instance" "gitlab" {
  count         = var.node_count
  instance_type = var.instance_type
  image_id      = coalesce(var.image_id, data.tencentcloud_images.ubuntu.images.0.image_id)

  availability_zone = data.tencentcloud_availability_zones.default.zones.0.name
  system_disk_type  = var.disk_type
  system_disk_size  = var.disk_size

  security_groups = var.security_group_ids
  vpc_id          = var.vpc_id
  subnet_id       = var.subnet_id

  instance_name = "${var.prefix}-${var.node_type}-${count.index + 1}"
  hostname      = "${var.prefix}-${var.node_type}-${count.index + 1}"

  allocate_public_ip         = true
  internet_max_bandwidth_out = 100

  key_name = var.ssh_key_name

  tags = {
    gitlab_node_prefix    = var.prefix
    gitlab_node_type      = var.node_type
    gitlab_node_level     = var.label_secondaries == true ? (count.index == 0 ? "${var.node_type}-primary" : "${var.node_type}-secondary") : ""
    gitlab_geo_site       = var.geo_site
    gitlab_geo_deployment = var.geo_deployment
    gitlab_geo_full_role  = var.geo_site == null ? null : (count.index == 0 ? "${var.geo_site}-${var.node_type}-primary" : "${var.geo_site}-${var.node_type}-secondary")
  }
}
