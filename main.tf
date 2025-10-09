// Data source to get the list of available AZs in the chosen region
data "aws_availability_zones" "available" {
  state = "available"
}

// 1. Create the Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true // Recommended for EC2 to resolve hostnames

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

// 2. Create the Internet Gateway (IGW)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id // Attach the IGW to the VPC [cite: 164]

  tags = {
    Name = "${var.project_name}-igw"
  }
}

// 3. Create 3 Public Subnets
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index] // Place each in a different AZ 
  map_public_ip_on_launch = true                                                     // Enable public IP assignment

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

// 4. Create 3 Private Subnets
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index] // Place each in a different AZ 

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

// 5. Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

// 6. Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

// 7. Create Public Route to the Internet Gateway
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"                 // The required destination CIDR block [cite: 167]
  gateway_id             = aws_internet_gateway.igw.id // Target is the IGW [cite: 167]
}

// 8. Associate all 3 Public Subnets with the Public Route Table
resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id // Attach all public subnets to the public RT [cite: 165]
}

// 9. Associate all 3 Private Subnets with the Private Route Table
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id // Attach all private subnets to the private RT [cite: 166]
}