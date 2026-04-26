provider "aws" {
  region = var.region
}

# ── Security Groups ──────────────────────────────────────────────────────────

resource "aws_security_group" "jenkins_controller_sg" {
  name        = "${var.environment}-jenkins-controller-sg"
  description = "Jenkins controller: allow 8080 from my IP, 22 from my IP"
  vpc_id      = var.vpc_id

  ingress {
    description = "Jenkins UI from my IP only"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description     = "SonarQube webhook callback from agent"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_agent_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-jenkins-controller-sg" }
}

resource "aws_security_group" "jenkins_agent_sg" {
  name        = "${var.environment}-jenkins-agent-sg"
  description = "Jenkins agent: allow SSH from controller only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from Jenkins controller"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_controller_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-jenkins-agent-sg" }
}

# ── IAM Role for agent EC2 (ECR + ECR auth + S3 deploy log) ─────────────────

data "aws_iam_policy_document" "agent_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_agent_role" {
  name               = "${var.environment}-jenkins-agent-role"
  assume_role_policy = data.aws_iam_policy_document.agent_assume.json
  tags               = { Name = "${var.environment}-jenkins-agent-role" }
}

data "aws_iam_policy_document" "agent_policy_doc" {
  statement {
    sid = "ECRAuth"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECRPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["arn:aws:ecr:${var.region}:*:repository/swapi-app"]
  }

  statement {
    sid = "S3DeployLog"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::swapi-terraform-state-d76255a5",
      "arn:aws:s3:::swapi-terraform-state-d76255a5/*"
    ]
  }

  statement {
    sid = "ALBBlueGreen"
    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:StartInstanceRefresh",
      "autoscaling:DescribeInstanceRefreshes",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:DescribeLaunchTemplates"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "agent_policy" {
  name   = "${var.environment}-jenkins-agent-policy"
  role   = aws_iam_role.jenkins_agent_role.id
  policy = data.aws_iam_policy_document.agent_policy_doc.json
}

resource "aws_iam_instance_profile" "agent_profile" {
  name = "${var.environment}-jenkins-agent-profile"
  role = aws_iam_role.jenkins_agent_role.name
}

# ── Jenkins Controller EC2 ───────────────────────────────────────────────────

resource "aws_instance" "jenkins_controller" {
  ami                         = var.ami_id
  instance_type               = var.controller_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins_controller_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/templates/controller-userdata.sh", {}))

  tags = { Name = "${var.environment}-jenkins-controller" }
}

# ── Jenkins Agent EC2 ────────────────────────────────────────────────────────

resource "aws_instance" "jenkins_agent" {
  ami                    = var.ami_id
  instance_type          = var.agent_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins_agent_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.agent_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/templates/agent-userdata.sh", {}))

  tags = { Name = "${var.environment}-jenkins-agent" }
}
