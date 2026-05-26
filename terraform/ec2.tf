# ---------------------------------------------------------------
# AMI : dernière Amazon Linux 2023 (x86_64)
# ---------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------
# Clé SSH
# ---------------------------------------------------------------
resource "aws_key_pair" "app" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------
# 2 instances app identiques — une par AZ (subnet privé)
# ---------------------------------------------------------------
resource "aws_instance" "app" {
  count = 2

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.private_app[count.index].id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.app.key_name

  user_data = templatefile("${path.module}/user_data/app.sh", {
    db_host     = aws_db_instance.main.address
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
    app_port    = tostring(var.app_port)
  })

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "${var.project_name}-app-${count.index + 1}"
    Environment = var.environment
    Role        = "app"
  }
}
