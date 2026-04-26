#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl gnupg2 software-properties-common unzip git python3 python3-pip python3-venv

# Java 17 (required for Jenkins agent)
apt-get install -y openjdk-17-jdk

# Create jenkins user and workspace
useradd -m -s /bin/bash jenkins || true
mkdir -p /home/ubuntu/jenkins
chown ubuntu:ubuntu /home/ubuntu/jenkins

# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-keyring.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# Terraform
TERRAFORM_VERSION="1.7.5"
curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    -o /tmp/terraform.zip
unzip -q /tmp/terraform.zip -d /usr/local/bin
rm /tmp/terraform.zip
chmod +x /usr/local/bin/terraform

# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
    sh -s -- -b /usr/local/bin

# tfsec
curl -fsSL "https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64" \
    -o /usr/local/bin/tfsec
chmod +x /usr/local/bin/tfsec

# SonarScanner CLI
SONAR_VERSION="5.0.1.3006"
curl -fsSL "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-linux.zip" \
    -o /tmp/sonar-scanner.zip
unzip -q /tmp/sonar-scanner.zip -d /opt
ln -sf /opt/sonar-scanner-${SONAR_VERSION}-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner
rm /tmp/sonar-scanner.zip

echo "Jenkins agent setup complete."
