# 取得子網域 hosted zone（在各自帳號：dev/demo 執行）
data "aws_route53_zone" "env_zone" {
  name         = "${var.env}.${var.root_domain}"
  private_zone = false
}

# 用 EC2 公網 IP 建 A 紀錄（最小可用）
# resource "aws_route53_record" "app_a" {
#   zone_id = data.aws_route53_zone.env_zone.zone_id
#   name    = "${var.env}.${var.root_domain}" # dev.ibchiang.me / demo.ibchiang.me
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.csye6225_app.public_ip] # 若你的 EC2 名稱不同，改成你的資源名
# }

# （可選）EIP 版本（較穩定）：
# resource "aws_eip" "app" {
#   vpc      = true
#   instance = aws_instance.csye6225_app.id
#   tags = { Name = "${var.env}-app-eip" }
# }
# resource "aws_route53_record" "app_a" {
#   zone_id = data.aws_route53_zone.env_zone.zone_id
#   name    = "${var.env}.${var.root_domain}"
#   type    = "A"
#   ttl     = 300
#   records = [aws_eip.app.public_ip]
# }

# ALB Alias 版本（可擴展）：
resource "aws_route53_record" "app_alias" {
  zone_id = data.aws_route53_zone.env_zone.zone_id
  name    = "${var.env}.${var.root_domain}" # dev.ibchiang.me / demo.ibchiang.me
  type    = "A"
  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = false
  }
}
