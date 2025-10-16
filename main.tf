# Data source to get the list of available AZs in the chosen region
data "aws_availability_zones" "available" {
  state = "available"
}

# Create the Virtual Private Cloud (VPC), recommended for EC2 to resolve hostnames
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create the Internet Gateway (IGW)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id # Attach the IGW to the VPC [cite: 164]

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create 3 Public Subnets
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index] # Place each in a different AZ 
  map_public_ip_on_launch = true                                                     # Enable public IP assignment

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# Create 3 Private Subnets
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index] # Place each in a different AZ 

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Create Public Route to the Internet Gateway
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"                 # The required destination CIDR block [cite: 167]
  gateway_id             = aws_internet_gateway.igw.id # Target is the IGW [cite: 167]
}

# Associate all 3 Public Subnets with the Public Route Table
resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id # Attach all public subnets to the public RT [cite: 165]
}

# Associate all 3 Private Subnets with the Private Route Table
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id # Attach all private subnets to the private RT [cite: 166]
}


# security group (do not open DB port 3306)
resource "aws_security_group" "a05_app_sg" {
  name        = "a05-app-sg"
  description = "Security group for the A05 application"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port"
    from_port   = var.app_port
    to_port     = var.app_port
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
    Name = "a05-app-sg"
  }
}


# EC2 instance
resource "aws_instance" "a05_app" {
  ami                         = var.app_ami_id
  instance_type               = "t3.micro"
  subnet_id                   = element(aws_subnet.public[*].id, 0)
  vpc_security_group_ids      = [aws_security_group.a05_app_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "a05-fastapi-instance"
  }
}
