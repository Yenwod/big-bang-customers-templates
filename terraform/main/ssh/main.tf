# Create SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key locally
resource "local_file" "pem" {
  filename        = pathexpand("${var.private_key_path}/${var.name}.pem")
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}