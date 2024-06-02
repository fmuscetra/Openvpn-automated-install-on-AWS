terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "main" {
  assign_generated_ipv6_cidr_block = true
  cidr_block                       = "10.0.0.0/16"

  tags = {
    Name = "VPC-1"
  }
}

# Create a subnet
resource "aws_subnet" "main" {
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = "10.0.1.0/24"
  availability_zone               = var.availability_zone
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "Subnet-1"
  }
}



# Create Internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "gw"
  }
}

# Route table 
resource "aws_default_route_table" "igw" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "igw"
  }
}

# Associate route table
resource "aws_route_table_association" "igw" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_default_route_table.igw.id
}

# Create Security group
resource "aws_security_group" "Openvpn" {
  name        = "openvpn"
  description = "Allow vpn and ssh traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "vpn-in"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ipv6-vpn-in"
    from_port        = 1194
    to_port          = 1194
    protocol         = "udp"
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ipv6-ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }


  tags = {
    Name = "Openvpn"
  }
}

# Create SSH-Key
resource "aws_key_pair" "admin" {
  key_name   = "admin"
  public_key = var.public_key
}


# Create instance
resource "aws_instance" "vpn-1" {
  ami                = var.ami #Image from the region image repo 
  instance_type      = var.instance_type
  subnet_id          = aws_subnet.main.id
  ipv6_address_count = 1
  private_ip         = "10.0.1.10"
  tags = {
    Name = "VPN-1"
  }
  # root disk
  root_block_device {
    volume_size           = "8"
    volume_type           = "standard"
    encrypted             = false
    delete_on_termination = true
  }
  key_name               = "admin"
  vpc_security_group_ids = [aws_security_group.Openvpn.id]
  user_data              = <<-EOL
  #!/bin/bash -xe
   echo "Started download"
   curl -O --output-dir /home/ubuntu https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
   chmod +x /home/ubuntu/openvpn-install.sh 
   echo "Started installation"
   export AUTO_INSTALL=y
   /home/ubuntu/openvpn-install.sh 
   cp /root/client.ovpn /home/ubuntu 
   init 6
   EOL
}

# Create EIP
resource "aws_eip" "eip-1" {
  vpc = true
}

# Associate EIP to instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.vpn-1.id
  allocation_id = aws_eip.eip-1.id
}


# Create SNS topic
resource "aws_sns_topic" "user_updates" {
  name = "cpu_load"
}

# Create SNS topic subscription
resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = "youremail@gmail.com"
}

# Create alarm CPUload 
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name                = "cpu-utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300" #seconds
  statistic                 = "Average"
  threshold                 = "20.0"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  actions_enabled           = "true"
  alarm_actions             = [aws_sns_topic.user_updates.arn]
  ok_actions                = [aws_sns_topic.user_updates.arn]
  insufficient_data_actions = []
  dimensions = {
    InstanceId = aws_instance.vpn-1.id
  }
} 

