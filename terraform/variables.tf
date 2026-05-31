variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "devops-final"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_instance_type" {
  description = "EC2 instance type for app servers"
  type        = string
  default     = "t3.small"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "appuser"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "app_port" {
  description = "Port the TypeScript SSR app listens on"
  type        = number
  default     = 3000
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}

variable "citools_instance_type" {
  description = "EC2 instance type for CI tools server (Jenkins + SonarQube + Nexus)"
  type        = string
  default     = "t3.medium"
}

variable "citools_domain" {
  description = "Domaine de base pour les outils CI (ex: citools.mondomaine.com)"
  type        = string
  default     = "citools.local"
}
