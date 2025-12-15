output "monitoring_ec2_public_ip" {
  value = aws_instance.monitoring_ec2.public_ip
  description = "IP publique de l'EC2 monitoring"
}
