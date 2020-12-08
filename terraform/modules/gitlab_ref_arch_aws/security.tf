resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.prefix}-ssh-key"
  public_key = var.ssh_key
}
