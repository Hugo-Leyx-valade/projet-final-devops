# ---------------------------------------------------------------
# Subnet public dédié — isolé du réseau applicatif
# CIDR index 30 → 10.0.30.0/24
# ---------------------------------------------------------------
resource "aws_subnet" "citools" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 30)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-citools"
    Environment = var.environment
    Tier        = "citools"
  }
}

resource "aws_route_table_association" "citools" {
  subnet_id      = aws_subnet.citools.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------
# Elastic IP fixe pour accès stable aux interfaces web
# ---------------------------------------------------------------
resource "aws_eip" "citools" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-citools-eip"
    Environment = var.environment
  }
}

resource "aws_eip_association" "citools" {
  instance_id   = aws_instance.citools.id
  allocation_id = aws_eip.citools.id
}

# ---------------------------------------------------------------
# Security group citools — ports CI uniquement, sans accès au sg-app
# ---------------------------------------------------------------
resource "aws_security_group" "citools" {
  name        = "${var.project_name}-sg-citools"
  description = "CI tools - Jenkins 8080, SonarQube 9000, Nexus 8081"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP redirect to HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS via Nginx reverse proxy"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Nexus Repository"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg-citools"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------
# Instance CI — t3.medium (Jenkins + SonarQube + Nexus)
# Disque 50 Go (artefacts Nexus + données SonarQube)
# ---------------------------------------------------------------
resource "aws_instance" "citools" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.citools_instance_type
  subnet_id                   = aws_subnet.citools.id
  vpc_security_group_ids      = [aws_security_group.citools.id]
  key_name                    = aws_key_pair.app.key_name
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "${var.project_name}-citools"
    Environment = var.environment
    Role        = "citools"
  }
}
