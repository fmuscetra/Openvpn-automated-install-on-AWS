output "IPv4_eip-1" {
  description = "Contains the public IP address"
  value       = aws_eip.eip-1.public_ip
}

output "IPv6_IP" {
  value = aws_instance.vpn-1.ipv6_addresses
}
