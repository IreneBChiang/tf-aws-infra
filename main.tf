###################################
# 基本網路
###################################

# 取得可用 AZ
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# 3 個 Public Subnets
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# 3 個 Private Subnets
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-public-rt" }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-private-rt" }
}

# Public route → IGW
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Subnet associations
resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

###################################
# Security Groups
###################################

# App SG（不要開 DB port）
resource "aws_security_group" "a05_app_sg" {
  name        = "a05-app-sg"
  description = "Security group for the A05 application"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port"
    protocol    = "tcp"
    from_port   = var.app_port
    to_port     = var.app_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "a05-app-sg" }
}

###################################
# EC2 instance
###################################

resource "aws_instance" "a05_app" {
  ami                         = var.app_ami_id
  instance_type               = "t3.micro"
  subnet_id                   = element(aws_subnet.public[*].id, 0)
  vpc_security_group_ids      = [aws_security_group.a05_app_sg.id]
  associate_public_ip_address = true

  # 讓 EC2 取得 S3 權限
  iam_instance_profile = aws_iam_instance_profile.app_profile.name

  # 等 RDS / S3 完成
  depends_on = [
    aws_db_instance.app_db,
    aws_s3_bucket.images
  ]

  # 這行保證只要 userdata 有變更，就會自動重建 EC2
  user_data_replace_on_change = true

  # 開機寫入 .env 並啟動服務
  user_data = templatefile("${path.module}/userdata.tpl", {
    app_port     = var.app_port
    rds_endpoint = aws_db_instance.app_db.address
    db_user      = var.db_username
    db_pass      = var.db_password
    db_name      = var.db_name
    s3_bucket    = aws_s3_bucket.images.bucket
    service_user = var.service_user
  })

  tags = { Name = "a05-fastapi-instance" }
}
