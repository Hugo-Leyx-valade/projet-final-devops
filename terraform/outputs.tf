output "alb_dns_name" {
  description = "DNS public de l'Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID de l'ALB (pour Route53)"
  value       = aws_lb.main.zone_id
}

output "app_instance_ids" {
  description = "IDs des instances applicatives"
  value       = aws_instance.app[*].id
}

output "app_private_ips" {
  description = "IPs privées des instances applicatives"
  value       = aws_instance.app[*].private_ip
}

output "db_endpoint" {
  description = "Endpoint RDS (accessible uniquement depuis le subnet privé)"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "s3_backup_bucket" {
  description = "Nom du bucket S3 pour les backups"
  value       = aws_s3_bucket.backups.bucket
}

output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}
