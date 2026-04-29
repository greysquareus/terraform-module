# Create the key pair
resource "tls_private_key" "web_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "web_key" {
  key_name   = var.key_name
  public_key = tls_private_key.web_key.public_key_openssh
}

# Save the private key to file
resource "local_file" "private_key_local" {
  content         = tls_private_key.web_key.private_key_pem
  filename        = "./${var.key_name}.pem"
  file_permission = "0400"
}
