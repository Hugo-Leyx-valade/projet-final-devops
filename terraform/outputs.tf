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

output "citools_public_ip" {
  description = "IP publique fixe de l'instance CI tools"
  value       = aws_eip.citools.public_ip
}

output "citools_instance_id" {
  description = "ID de l'instance CI tools"
  value       = aws_instance.citools.id
}

output "citools_urls" {
  description = "URLs d'accès aux outils CI (via HTTPS Nginx)"
  value = {
    jenkins   = "https://${aws_eip.citools.public_ip}:8080 ou https://jenkins.${var.citools_domain}"
    sonarqube = "https://${aws_eip.citools.public_ip}:9000 ou https://sonarqube.${var.citools_domain}"
    nexus     = "https://${aws_eip.citools.public_ip}:8081 ou https://nexus.${var.citools_domain}"
  }
}
