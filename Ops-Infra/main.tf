terraform {
  backend "s3" {
    bucket = "tf-state-praveen2-2025"
    key    = "finance-app/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# --- Security Group ---
resource "aws_security_group" "finance_docker_sg" {
  name        = "finance-docker-sg"
  description = "Allow SSH and Port 5000"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask App"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 Instance ---
resource "aws_instance" "finance_server" {
  ami           = "ami-068c0051b15cdb816" # Amazon Linux 2023 (US-East-1)
  instance_type = "t3.micro"
  key_name      = var.key_name
  security_groups = [aws_security_group.finance_docker_sg.name]

  tags = {
    Name = "Finance-Docker-Server"
  }

  # AUTOMATED SETUP SCRIPT
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf remove -y podman podman-docker
              dnf install -y docker git
              service docker start
              systemctl enable docker
              usermod -a -G docker ec2-user
              EOF
}

# --- NEW: Generate Ansible Inventory File ---
resource "local_file" "ansible_inventory" {
  # We use "../" to go back one folder out of Ops-Infra, then into Ansible
  filename = "${path.module}/../Ansible/hosts.ini"
  
  # This content will be written to the file
  content = <<EOT
[webserver]
${aws_instance.finance_server.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOT
}