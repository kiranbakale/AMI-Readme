resource "aws_instance" "gitlab" {
  count = var.node_count
  instance_type = var.instance_type
  ami = var.ami_id
  key_name = var.ssh_key_name
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile = var.iam_instance_profile

  root_block_device {
    volume_type = var.disk_type
    volume_size = var.disk_size
  }
 
  tags = {
    Name = "${var.prefix}-${var.node_type}-${count.index + 1}"
    gitlab_node_prefix = var.prefix
    gitlab_node_type = var.node_type
    gitlab_node_level = var.label_secondaries == true ? (count.index == 0 ? "${var.node_type}-primary" : "${var.node_type}-secondary") : ""
    gitlab_geo_site = var.geo_site
    gitlab_geo_deployment = var.geo_deployment
    gitlab_geo_full_role = var.geo_site == null ? null : (count.index == 0 ? "${var.geo_site}-${var.node_type}-primary" : "${var.geo_site}-${var.node_type}-secondary")
  }
}

resource "aws_eip_association" "gitlab" {
  count = length(var.elastic_ip_allocation_ids)

  instance_id = aws_instance.gitlab[count.index].id
  allocation_id = var.elastic_ip_allocation_ids[count.index]
}