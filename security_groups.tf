# Security Groups

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "csye6225-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Allow inbound HTTP/HTTPS from the internet
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

  # Allow all outbound
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "csye6225-alb-sg" }
}

# App Security Group（被 ALB 打進來）
resource "aws_security_group" "csye6225_app_sg" {
  name        = "csye6225-app-sg"
  description = "Security group for web application behind ALB"
  vpc_id      = aws_vpc.main.id

  # SSH – optional, for debugging only(可改成你自己的 IP)  
  ingress {
    description = "SSH"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP only from ALB SG
  ingress {
    description     = "HTTP from ALB"
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb_sg.id]
  }

  # (不再允許 HTTPS 或 APP_PORT 從外部進來)
  # 所有出站流量允許
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "csye6225-app-sg" }
}