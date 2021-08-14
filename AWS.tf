provider "aws" {
    region = var.region
    access_key = var.access_key
    secret_key = var.secret_key
}
locals {
  nameprefix = "TERRAFORM-I01-"
}

# VPC
resource "aws_vpc" "myOnlyVPC" {
    cidr_block       = "10.0.0.0/16"
    instance_tenancy = "default"

    tags = {
        Name = "${local.nameprefix}vpc"
    }
}

# SUBNET
resource "aws_subnet" "mySubNet-1" {
    vpc_id     = aws_vpc.myOnlyVPC.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "${local.nameprefix}subnet"
    }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "myGateWay" {
    vpc_id = aws_vpc.myOnlyVPC.id

    tags = {
        Name = "${local.nameprefix}gateway"
    }
}

# ROUTE TABLE
resource "aws_route_table" "myRouteTable" {
    vpc_id = aws_vpc.myOnlyVPC.id
        
    route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.myGateWay.id
        }

    tags = {
        Name = "${local.nameprefix}routeTable"
    }
}

# ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mySubNet-1.id
  route_table_id = aws_route_table.myRouteTable.id
}

# SECURITY GROUPS
resource "aws_security_group" "mySecurityGroup" {
  name        = "mySecurityGroup_allowWebTraffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myOnlyVPC.id

    ingress {
        description      = "TLS from VPC"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        #   cidr_blocks      = [aws_vpc.myOnlyVPC.cidr_block]
    }
    ingress {
        description      = "HTTP from VPC"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        #   cidr_blocks      = [aws_vpc.myOnlyVPC.cidr_block]
    }
    ingress {
        description      = "SSH from VPC"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        #   cidr_blocks      = [aws_vpc.myOnlyVPC.cidr_block]
    }
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "${local.nameprefix}WEB"
    }
}

# NETWORK INTERFACE
resource "aws_network_interface" "myNetworkInterface" {
  subnet_id       = aws_subnet.mySubNet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.mySecurityGroup.id]
}

# ELASTIC IP
resource "aws_eip" "myEIP" {
  vpc                       = true
  network_interface         = aws_network_interface.myNetworkInterface.id
  associate_with_private_ip = "10.0.1.50" #same as provided in the network_interface
  depends_on = [aws_internet_gateway.myGateWay]
}

# EC2 INSTANCES
resource "aws_instance" "test-html-site"{
    ami = "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    # the .pem key created on AWS
    key_name = "TERRAFORM-I04-key"
    network_interface {
        device_index = 0 
        network_interface_id = aws_network_interface.myNetworkInterface.id
    }
    tags = {
        Name = "${local.nameprefix}html-site"
    }

    # commands to run in order to install apache2
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                cd /var/www/html
                sudo rm -f *
                sudo git clone https://github.com/AymKh/rockPaperScissors.git
                sudo mv rockPaperScissors/* .
                EOF

}