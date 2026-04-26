variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID from Assignment 3"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for Jenkins controller"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for Jenkins agent"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "my_ip" {
  description = "Your public IP for SSH/8080 access (CIDR notation)"
  type        = string
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "controller_instance_type" {
  description = "Instance type for Jenkins controller"
  type        = string
  default     = "t3.medium"
}

variable "agent_instance_type" {
  description = "Instance type for Jenkins agent"
  type        = string
  default     = "t3.small"
}
