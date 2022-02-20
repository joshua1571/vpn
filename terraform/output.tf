output "my_console_output" {
  value = aws_instance.vpn_server.public_ip
}