# 先判斷現在是不是 dev 環境
locals {
  is_dev = var.env == "dev"
}

# dev：直接用 ACM 申請（只有 env=dev 才會建立這些資源）

# 這個 zone 是你 dev.ibchiang.me 的那個 hosted zone
data "aws_route53_zone" "dev" {
  count        = local.is_dev ? 1 : 0
  name         = var.dev_domain # dev.ibchiang.me
  private_zone = false
}

# 申請 ACM 憑證（公用、給 ALB 用）
resource "aws_acm_certificate" "dev" {
  count             = local.is_dev ? 1 : 0
  domain_name       = var.dev_domain # 必須是 dev.ibchiang.me
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# 先把 domain_validation_options 轉成 list，拿第一個
locals {
  dev_cert_dns = local.is_dev ? tolist(aws_acm_certificate.dev[0].domain_validation_options)[0] : null
}

# 把 ACM 要求的 CNAME 寫進 Route53
resource "aws_route53_record" "dev_cert_validation" {
  count   = local.is_dev ? 1 : 0
  zone_id = data.aws_route53_zone.dev[0].zone_id

  name = local.dev_cert_dns.resource_record_name
  type = local.dev_cert_dns.resource_record_type
  ttl  = 60

  records = [local.dev_cert_dns.resource_record_value]
}

# 讓 ACM 知道「DNS record 已經建了，可以發 Issued 憑證了」
resource "aws_acm_certificate_validation" "dev" {
  count = local.is_dev ? 1 : 0

  certificate_arn         = aws_acm_certificate.dev[0].arn
  validation_record_fqdns = [aws_route53_record.dev_cert_validation[0].fqdn]
}

# demo：用匯入的憑證 ARN（ZeroSSL）
# demo 不需要再找 Route53 zone 或申請 ACM，
# 直接在 demo.tfvars 裡提供 acm_certificate_arn 即可。
#
# demo.tfvars:
# env                = "demo"
# acm_certificate_arn = "arn:aws:acm:us-east-1:...."
