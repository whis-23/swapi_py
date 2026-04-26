provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "swapi-terraform-state-d76255a5"
    key            = "assignment4/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# Reuse outputs from Assignment 3 (remote state)
data "terraform_remote_state" "assignment3" {
  backend = "s3"
  config = {
    bucket = "swapi-terraform-state-d76255a5"
    key    = "dev/terraform.tfstate"
    region = var.region
  }
}

locals {
  vpc_id            = data.terraform_remote_state.assignment3.outputs.vpc_id
  public_subnet_ids = data.terraform_remote_state.assignment3.outputs.public_subnet_ids
  private_subnet_id = data.terraform_remote_state.assignment3.outputs.private_subnet_ids[0]
}

# ── ECR Repository ────────────────────────────────────────────────────────────

module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  image_name  = "swapi-app"
}

# ── Blue-Green ALB + ASGs ─────────────────────────────────────────────────────

module "blue_green" {
  source            = "./modules/blue-green"
  vpc_id            = local.vpc_id
  public_subnet_ids = local.public_subnet_ids
  alb_sg_id         = var.alb_sg_id
  web_sg_id         = var.web_sg_id
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  environment       = var.environment
  ecr_image_uri     = "${module.ecr.ecr_repository_url}:main"
}

# ── SonarQube EC2 ─────────────────────────────────────────────────────────────

module "sonarqube" {
  source           = "./modules/sonarqube"
  vpc_id           = local.vpc_id
  public_subnet_id = local.public_subnet_ids[0]
  my_ip            = var.my_ip
  agent_sg_id      = var.jenkins_agent_sg_id
  ami_id           = var.ami_id
  key_name         = var.key_name
  environment      = var.environment
}
