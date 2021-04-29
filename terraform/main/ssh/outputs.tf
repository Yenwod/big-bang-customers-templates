output "key_name" {
  value = aws_key_pair.ssh.key_name
}

output "public_key" {
  value = tls_private_key.ssh.public_key_openssh
}