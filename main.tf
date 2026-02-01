terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


data "aws_vpc" "default" {
  default = true
}


resource "aws_security_group" "ec2_sg" {
  name        = "clo835-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "clo835-ec2-sg"
  }
}


data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


resource "aws_instance" "clo835" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              EOF

  tags = {
    Name = "clo835-ec2"
  }
}

resource "aws_ecr_repository" "app" {
  name                 = "clo835-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "clo835-app"
  }
}

# ECR Repository для MySQL
resource "aws_ecr_repository" "mysql" {
  name                 = "clo835-mysql"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "clo835-mysql"
  }
}

# Outputs
output "ec2_public_ip" {
  value       = aws_instance.clo835.public_ip
  description = "Public IP of EC2 instance"
}

output "ecr_app_uri" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR URI for app"
}

output "ecr_mysql_uri" {
  value       = aws_ecr_repository.mysql.repository_url
  description = "ECR URI for MySQL"
}

output "aws_region" {
  value       = "us-east-1"
  description = "AWS Region"
}
