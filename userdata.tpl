#!/usr/bin/env bash
set -euxo pipefail

# 確保服務帳號存在（若 AMI 已建會略過）
id -u ${service_user} >/dev/null 2>&1 || \
  useradd --system --no-create-home --shell /usr/sbin/nologin ${service_user}

# 建設定目錄，讓群組(=service_user)可進
install -d -m 0750 -o root -g ${service_user} /etc/myapp

# Fetch DB password from AWS Secrets Manager (A09 requirement)
REGION="${region}"
DB_SECRET_ARN="${db_secret_arn}"

# 安裝 awscli / python3（部分 AMI 可能沒有）
if ! command -v aws >/dev/null 2>&1; then
  if command -v yum >/dev/null 2>&1; then
    # Amazon Linux / RHEL
    yum install -y awscli
  elif command -v apt-get >/dev/null 2>&1; then
    # Ubuntu / Debian：用官方 AWS CLI v2 安裝方式
    apt-get update -y
    apt-get install -y unzip curl

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
  fi
fi

# 確保有 python3
if ! command -v python3 >/dev/null 2>&1; then
  if command -v yum >/dev/null 2>&1; then
    yum install -y python3
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -y && apt-get install -y python3
  fi
fi

# 從 Secrets Manager 抓出密碼（一次 pipeline，避免 heredoc 怪問題）
DB_PASSWORD=$(
  aws secretsmanager get-secret-value \
    --secret-id "$DB_SECRET_ARN" \
    --region "$REGION" \
    --query 'SecretString' \
    --output text \
  | python3 -c 'import sys, json; print(json.loads(sys.stdin.read())["password"])'
)

# 如果長度是 0，直接噴錯結束，避免寫出沒有密碼的 URL
if [ -z "$DB_PASSWORD" ]; then
  echo "FATAL: DB_PASSWORD is empty!" >&2
  exit 1
fi

# 寫入 .env，擁有者 root:service_user，群組可讀
cat >/etc/myapp/.env <<EOF
APP_PORT=${app_port}
DATABASE_URL=mysql+pymysql://${db_user}:$DB_PASSWORD@${rds_endpoint}:3306/${db_name}
S3_BUCKET_NAME=${s3_bucket}
USER_SIGNUP_TOPIC_ARN=${user_signup_topic_arn}
AWS_REGION=${region}
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

# 安裝與設定 Nginx 反向代理 (listen 80)
if command -v yum >/dev/null 2>&1; then
  # Amazon Linux / RHEL 家族
  if command -v amazon-linux-extras >/dev/null 2>&1; then
    amazon-linux-extras install -y nginx1 || yum install -y nginx
  else
    yum install -y nginx
  fi

  # 使用 /etc/nginx/conf.d，Amazon Linux 會自動 include
  install -d -m 0755 /etc/nginx/conf.d
  cat >/etc/nginx/conf.d/myapp.conf <<EOF
server {
    listen 80 default_server;
    server_name _;

    client_max_body_size 6m;

    location / {
        # 注意：結尾不要加斜線，避免將 /healthz 重寫掉
        proxy_pass http://127.0.0.1:${app_port};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 120;
    }
}
EOF

  # 移除可能存在的預設站台，避免吃到 default
  rm -f /etc/nginx/conf.d/default.conf || true

elif command -v apt-get >/dev/null 2>&1; then
  # Ubuntu / Debian
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y nginx

  # Ubuntu 使用 sites-available / sites-enabled
  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  cat >/etc/nginx/sites-available/webapp <<'EOF'
server {
    listen 80 default_server;
    server_name _;

    client_max_body_size 6m;

    location / {
        proxy_pass http://127.0.0.1:__APP_PORT__;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 120;
    }
}
EOF
  # 將佔位符換成實際 app_port
  sed -i "s/__APP_PORT__/${app_port}/g" /etc/nginx/sites-available/webapp

  ln -sf /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/webapp
  # 移除預設站台
  rm -f /etc/nginx/sites-enabled/default || true
  rm -f /etc/nginx/conf.d/default.conf || true
fi

# 驗證並啟動/重載 Nginx
nginx -t
systemctl enable --now nginx
systemctl reload nginx || true

# # CloudWatch Agent 安裝
# if ! command -v amazon-cloudwatch-agent >/dev/null 2>&1; then
#   if command -v yum >/dev/null 2>&1; then
#     yum install -y amazon-cloudwatch-agent
#   elif command -v apt-get >/dev/null 2>&1; then
#     apt-get update -y
#     wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
#     apt-get install -y ./amazon-cloudwatch-agent.deb
#   fi
# fi

# # 準備 webapp 日誌檔 (先寫一行，讓 Log Stream 立即被建立）
# install -d -m 0755 /var/log/webapp
# touch /var/log/webapp/app.log
# chown ${service_user}:${service_user} /var/log/webapp/app.log
# chmod 0664 /var/log/webapp/app.log
# echo "bootstrap cw $(date -u +%FT%TZ)" >> /var/log/webapp/app.log || true

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

