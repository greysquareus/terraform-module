output "public_ip" {
  value = aws_eip.eip.public_ip
}

output "public_dns" {
  value = aws_eip.eip.public_dns
}

output "eip_id" {
  value = aws_eip.eip.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_id" {
  value = aws_subnet.subnet.id
}

output "sec_group_id" {
  value = [aws_security_group.sec_group.id]
}