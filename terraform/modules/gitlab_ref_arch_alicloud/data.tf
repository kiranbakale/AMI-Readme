data "alicloud_images" "ubuntu_18_04" {
  owners     = "system"
  name_regex = "^ubuntu_18_04"
}
