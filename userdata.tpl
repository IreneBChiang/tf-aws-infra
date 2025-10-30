#!/usr/bin/env bash
set -euxo pipefail

# 確保服務帳號存在（若 AMI 已建會略過）
id -u ${service_user} >/dev/null 2>&1 || \
  useradd --system --no-create-home --shell /usr/sbin/nologin ${service_user}

# 建設定目錄，讓群組(=service_user)可進
install -d -m 0750 -o root -g ${service_user} /etc/myapp

# 寫入 .env，擁有者 root:service_user，群組可讀
cat >/etc/myapp/.env <<EOF
APP_PORT=${app_port}
DATABASE_URL=mysql+pymysql://${db_user}:${db_pass}@${rds_endpoint}:3306/${db_name}
S3_BUCKET_NAME=${s3_bucket}
EOF
chown root:${service_user} /etc/myapp/.env
chmod 0640 /etc/myapp/.env

# 把應用目錄歸給服務帳號，避免存取問題
if [ -d /opt/myapp ]; then
  chown -R ${service_user}:${service_user} /opt/myapp || true
fi

# 讓 systemd 重新讀取並啟動服務
systemctl daemon-reload || true
systemctl enable myapp.service || true
systemctl restart myapp.service || true

# CloudWatch Agent 安裝
if ! command -v amazon-cloudwatch-agent >/dev/null 2>&1; then
  if command -v yum >/dev/null 2>&1; then
    yum install -y amazon-cloudwatch-agent
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    apt-get install -y ./amazon-cloudwatch-agent.deb
  fi
fi


# 準備 webapp 日誌檔 (先寫一行，讓 Log Stream 立即被建立）
install -d -m 0755 /var/log/webapp
touch /var/log/webapp/app.log
chown ${service_user}:${service_user} /var/log/webapp/app.log
chmod 0664 /var/log/webapp/app.log
echo "bootstrap cw $(date -u +%FT%TZ)" >> /var/log/webapp/app.log || true

# 寫入 CloudWatch Agent 設定
install -d -m 0755 /opt/aws/amazon-cloudwatch-agent/etc
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
${cwagent_config_json}
JSON
chown root:root /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
chmod 0644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 啟動 CloudWatch Agent
systemctl enable amazon-cloudwatch-agent || true
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop || true
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
systemctl start amazon-cloudwatch-agent

