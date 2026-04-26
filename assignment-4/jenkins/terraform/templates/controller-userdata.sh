#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl gnupg2 software-properties-common unzip git

# Java 17
apt-get install -y openjdk-17-jdk
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/environment

# Jenkins LTS
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
    gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list
apt-get update -y
apt-get install -y jenkins

# Set Jenkins port to 8080 (default)
sed -i 's/^HTTP_PORT=.*/HTTP_PORT=8080/' /etc/default/jenkins 2>/dev/null || true

systemctl enable jenkins
systemctl start jenkins

# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /usr/share/keyrings/docker-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-keyring.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker jenkins
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

# Trivy (for container scanning)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
    sh -s -- -b /usr/local/bin

# tfsec (for Terraform scanning)
curl -fsSL "https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64" \
    -o /usr/local/bin/tfsec
chmod +x /usr/local/bin/tfsec

echo "Jenkins controller setup complete."
