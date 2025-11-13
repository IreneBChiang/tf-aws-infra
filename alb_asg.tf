# Application Load Balancer + ASG + Scaling Policy

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "csye6225-app-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name        = "csye6225-app-alb"
    Environment = var.env
  }
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name        = "csye6225-app-tg"
  port        = 80 # userdata 裡 Nginx 監聽 80，再反代到 APP_PORT
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    path                = "/healthz"
    matcher             = "200-399"
    interval            = 90
    timeout             = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "csye6225-app-tg"
    Environment = var.env
  }
}

# 給使用者用的 HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = aws_acm_certificate_validation.dev.certificate_arn # dev 用 ACM，demo 改成 data 取匯入憑證

  certificate_arn = var.env == "dev" ? aws_acm_certificate_validation.dev[0].certificate_arn : var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn # 這個 TG 的 port 還是 80
  }
}

# Launch Template
resource "aws_launch_template" "app_lt" {
  name_prefix   = "csye6225-app-"
  image_id      = var.app_ami_id
  instance_type = var.app_instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  # vpc_security_group_ids = [aws_security_group.csye6225_app_sg.id]

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.csye6225_app_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    region       = var.aws_region
    app_port     = var.app_port
    rds_endpoint = aws_db_instance.app_db.address
    db_user      = var.db_username
    # db_pass        = var.db_password
    db_secret_arn         = aws_secretsmanager_secret.db.arn
    db_name               = var.db_name
    s3_bucket             = aws_s3_bucket.images.bucket
    service_user          = var.service_user
    env                   = var.env
    log_group_name        = var.log_group_name
    user_signup_topic_arn = aws_sns_topic.user_signup.arn
    cwagent_config_json = templatefile("${path.module}/cwagent.json.tpl", {
      env            = var.env
      log_group_name = var.log_group_name
    })
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "csye6225-app"
      Project     = var.project_name
      Environment = var.env
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                      = "csye6225_asg"
  min_size                  = 3
  max_size                  = 5
  desired_capacity          = 3
  default_cooldown          = 60
  vpc_zone_identifier       = aws_subnet.public[*].id
  health_check_type         = "ELB"
  health_check_grace_period = 60
  target_group_arns         = [aws_lb_target_group.app_tg.arn]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app_lt.id
        version            = "$Latest"
      }
      # 依優先順序（沒設 priority 時，照宣告順序）
      override { instance_type = "t3a.micro" } # 先用這個
      override { instance_type = "t3.micro" }  # 不夠再試這個
      override { instance_type = "t2.micro" }  # 再不夠用這個
    }
    # 只用 On-Demand（沒有 Spot），維持預設就行
    instances_distribution {
      on_demand_percentage_above_base_capacity = 100
    }
  }

  tag {
    key                 = "Name"
    value               = "csye6225-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# AutoScaling Policies + CloudWatch Alarms

# Scale Up：CPU > 5% 時增加 1 台
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "cpu-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-gt-5"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

# Scale Down：CPU < 3% 時減少 1 台
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "cpu-scale-down"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-lt-3"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 3

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}
