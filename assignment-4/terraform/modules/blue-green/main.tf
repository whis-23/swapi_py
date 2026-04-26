# ── Target Groups ────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "blue" {
  name     = "tg-blue"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = { Name = "${var.environment}-tg-blue" }
}

resource "aws_lb_target_group" "green" {
  name     = "tg-green"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = { Name = "${var.environment}-tg-green" }
}

# ── ALB + Listeners ───────────────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.environment}-swapi-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]

  tags = { Name = "${var.environment}-swapi-alb" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Blue starts as live
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

# Test listener on port 8081 — used by smoke test to hit the idle color
# (port 8080 is reserved for Jenkins)
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8081
  protocol          = "HTTP"

  # Green starts as idle (smoke test target)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}

# ── Launch Templates ──────────────────────────────────────────────────────────

resource "aws_launch_template" "blue" {
  name_prefix   = "${var.environment}-lt-blue-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.web_sg_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    docker run -d -p 5000:5000 --name swapi-app ${var.ecr_image_uri}
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.environment}-blue" }
  }
}

resource "aws_launch_template" "green" {
  name_prefix   = "${var.environment}-lt-green-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.web_sg_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    docker run -d -p 5000:5000 --name swapi-app ${var.ecr_image_uri}
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.environment}-green" }
  }
}

# ── Auto Scaling Groups ───────────────────────────────────────────────────────

resource "aws_autoscaling_group" "blue" {
  name                = "asg-blue"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.public_subnet_ids
  target_group_arns   = [aws_lb_target_group.blue.arn]

  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-blue"
    propagate_at_launch = true
  }

  tag {
    key                 = "Color"
    value               = "blue"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "green" {
  name                = "asg-green"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.public_subnet_ids
  target_group_arns   = [aws_lb_target_group.green.arn]

  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-green"
    propagate_at_launch = true
  }

  tag {
    key                 = "Color"
    value               = "green"
    propagate_at_launch = true
  }
}
