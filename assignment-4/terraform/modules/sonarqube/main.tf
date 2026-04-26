variable "vpc_id" {
  type = string
}
variable "public_subnet_id" {
  type = string
}
variable "my_ip" {
  type = string
}
variable "agent_sg_id" {
  type = string
}
variable "ami_id" {
  type    = string
  default = "ami-0c7217cdde317cfec"
}
variable "key_name" {
  type = string
}
variable "environment" {
  type    = string
  default = "dev"
}

resource "aws_security_group" "sonarqube_sg" {
  name        = "${var.environment}-sonarqube-sg"
  description = "SonarQube: port 9000 to my IP and Jenkins agent only"
  vpc_id      = var.vpc_id

  ingress {
    description = "SonarQube UI from my IP"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description     = "SonarQube from Jenkins agent"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [var.agent_sg_id]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-sonarqube-sg" }
}

resource "aws_instance" "sonarqube" {
  ami                         = var.ami_id
  instance_type               = "t3.small"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.sonarqube_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = base64encode(<<-EOF
    #!/usr/bin/env bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y
    apt-get install -y docker.io docker-compose curl unzip

    systemctl enable docker
    systemctl start docker

    # Increase vm.max_map_count for Elasticsearch inside SonarQube
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    sysctl -w vm.max_map_count=262144

    mkdir -p /opt/sonarqube
    cat > /opt/sonarqube/docker-compose.yml <<'COMPOSE'
    version: "3"
    services:
      sonarqube:
        image: sonarqube:10-community
        container_name: sonarqube
        restart: unless-stopped
        ports:
          - "9000:9000"
        environment:
          - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
        volumes:
          - sonar_data:/opt/sonarqube/data
          - sonar_logs:/opt/sonarqube/logs
          - sonar_extensions:/opt/sonarqube/extensions
    volumes:
      sonar_data:
      sonar_logs:
      sonar_extensions:
    COMPOSE

    cd /opt/sonarqube && docker-compose up -d
    echo "SonarQube setup complete."
  EOF
  )

  tags = { Name = "${var.environment}-sonarqube" }
}

output "sonarqube_public_ip" {
  value = aws_instance.sonarqube.public_ip
}

output "sonarqube_sg_id" {
  value = aws_security_group.sonarqube_sg.id
}
