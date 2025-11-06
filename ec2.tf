# EC2 instance

# resource "aws_instance" "csye6225_app" {
#   count = var.enable_single_instance ? 1 : 0
#   ami                         = var.app_ami_id
#   instance_type               = "t3.micro"
#   subnet_id                   = element(aws_subnet.public[*].id, 0)
#   vpc_security_group_ids      = [aws_security_group.csye6225_app_sg.id]
#   associate_public_ip_address = true

#   # 讓 EC2 取得 S3 權限
#   iam_instance_profile = aws_iam_instance_profile.app_profile.name

#   # 等 RDS / S3 完成
#   depends_on = [
#     aws_db_instance.app_db,
#     aws_s3_bucket.images
#   ]

#   # 這行保證只要 userdata 有變更，就會自動重建 EC2
#   user_data_replace_on_change = true

#   # 開機寫入 .env 並啟動服務
#   user_data = templatefile("${path.module}/userdata.tpl", {
#     app_port     = var.app_port
#     rds_endpoint = aws_db_instance.app_db.address
#     db_user      = var.db_username
#     db_pass      = var.db_password
#     db_name      = var.db_name
#     s3_bucket    = aws_s3_bucket.images.bucket
#     service_user = var.service_user

#     # Assignment07 新增
#     env            = var.env
#     log_group_name = var.log_group_name

#     # 將 CloudWatch Agent 設定渲染成 JSON 傳進 userdata
#     cwagent_config_json = templatefile("${path.module}/cwagent.json.tpl", {
#       env            = var.env
#       log_group_name = var.log_group_name
#     })
#   })

#   tags = { Name = "CSYE6225" }
# }