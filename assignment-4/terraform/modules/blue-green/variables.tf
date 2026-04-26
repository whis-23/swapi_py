variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "alb_sg_id" {
  type = string
}
variable "web_sg_id" {
  type = string
}
variable "ami_id" {
  type = string
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "key_name" {
  type = string
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "ecr_image_uri" {
  type        = string
  description = "Initial image URI for both ASGs"
}
