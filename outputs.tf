output "eip-1" {
  description = "Contains the public IP address"
  value       = aws_eip.eip-1.public_ip
}