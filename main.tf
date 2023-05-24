provider "aws" {
    region = "ap-south-1"
    profile = "Terraform"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "mainVPC"
  }
}

# Security Group for EC2
resource "aws_security_group" "sec_grp" {
  name        = "Web Security Group"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Web Security Group"
  }
}

# EC2
resource "aws_instance" "instance" {
  ami = "ami-07d3a50bd29811cd1"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public1.id
  vpc_security_group_ids = [ aws_security_group.sec_grp.id ]
  tags = {
    "Name" = "mainec2"
  }
}

# AWS EIP
resource "aws_eip" "web_ip" {
  instance = aws_instance.instance.id
  vpc = true
}

# Public Subnet 1
resource "aws_subnet" "public1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "Public Subnet"
  }
}

# Public Subnet 2
resource "aws_subnet" "public2" {
  availability_zone = "ap-south-1b"
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "Public Subnet"
  }
}

# Public Subnet 3
resource "aws_subnet" "public3" {
  availability_zone = "ap-south-1c"
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  tags = {
    Name = "Public Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "Private Subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "Main IGW"
  }
  
}

# Public Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    "Name" = "Public Route Table"
  }
}

# Private Route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "Private Route Table"
  }
}

# Public Route Table Association 1
resource "aws_route_table_association" "public_associate_1" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

# Public Route Table Association 2
resource "aws_route_table_association" "public_associate_2" {
  subnet_id = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# Public Route Table Association 3
resource "aws_route_table_association" "public_associate_3" {
  subnet_id = aws_subnet.public3.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table Association
resource "aws_route_table_association" "private_associate" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Database Security Group
resource "aws_security_group" "db_sec_grp" {
  name        = "DB Security Group"
  description = "Enable mysql access on port 3306"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "mysql access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_groups = [ aws_security_group.sec_grp.id ]  # allows traffic from this security group
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "DB Security Group"
  }
}


# DB Subnet group
resource "aws_db_subnet_group" "db_subnet_grp" {
  name = "db_subnets"
  subnet_ids = [aws_subnet.public2.id, aws_subnet.public3.id]
  description = "Subnets for RDS"

  tags = {
    name = "db_subnets"
  }
}

# RDS
resource "aws_db_instance" "db_instance" {
  identifier           = "maininstance"
  username             = "bavan"
  password             = "bavanbavan"
  db_name              = "mymaindb"
  engine               = "mysql"
  multi_az             = true
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  allocated_storage    = 10
  db_subnet_group_name = aws_db_subnet_group.db_subnet_grp.name
  vpc_security_group_ids = [aws_security_group.db_sec_grp.id]
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}