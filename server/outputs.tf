output "region" {
  value = var.region
}

output "instance_id" {
  value = aws_instance.name.id
}