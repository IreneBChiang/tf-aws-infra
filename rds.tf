# DB Security Group：只允許 app_sg 進來
resource "aws_security_group" "db_sg" {
  name   = "a06-db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "MySQL from app_sg"
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.csye6225_app_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "a06-db-sg" }
}

# RDS Subnet Group（用私有子網）
resource "aws_db_subnet_group" "db_subnets" {
  name       = "a06-db-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "a06-db-subnets" }
}

# 自訂 Parameter Group（不要 default）
resource "aws_db_parameter_group" "mysql_params" {
  name        = "csye6225-mysql-params"
  family      = "mysql8.0" # 與 engine_version 對應
  description = "Custom parameter group for MySQL"
  tags        = { Name = "csye6225-mysql-params" }

  # 範例參數，可依需求增修
  parameter {
    name  = "max_connections"
    value = "150"
  }
}

# RDS instance（私有、禁公開）
resource "aws_db_instance" "app_db" {
  identifier        = "csye6225"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = jsondecode(
    aws_secretsmanager_secret_version.db.secret_string
  )["password"]

  multi_az            = false
  publicly_accessible = false

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  parameter_group_name   = aws_db_parameter_group.mysql_params.name

  skip_final_snapshot = true

  tags = { Name = "a06-app-db" }
}

output "rds_endpoint" {
  value       = aws_db_instance.app_db.address
  description = "RDS endpoint hostname"
}
