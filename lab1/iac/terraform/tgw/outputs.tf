output "public_ec2" {
  value = aws_instance.web.public_ip
}

output "customer_gateway_ec2" {
  value = aws_instance.cgw_instance.public_ip
}
