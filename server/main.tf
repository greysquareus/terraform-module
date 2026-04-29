resource "aws_instance" "name" {
  instance_type               = var.instance_type
  ami                         = data.aws_ami.latest_ubuntu.id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.web_key.key_name
  vpc_security_group_ids      = var.sec_group_id

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_key.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt install -y apache2",
      "sudo systemctl start apache2"
    ]
  }
}