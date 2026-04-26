variable "region" {
  type    = string
  default = "us-east-1"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "ami_id" {
  type        = string
  description = "Ubuntu 22.04 AMI ID"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "key_name" {
  type = string
}
variable "my_ip" {
  type        = string
  description = "Your public IP in CIDR (x.x.x.x/32)"
}
variable "alb_sg_id" {
  type        = string
  description = "ALB security group ID from Assignment 3"
}
variable "web_sg_id" {
  type        = string
  description = "Web/app security group ID from Assignment 3"
}
variable "jenkins_agent_sg_id" {
  type        = string
  description = "Jenkins agent SG -- grants SonarQube access"
}
