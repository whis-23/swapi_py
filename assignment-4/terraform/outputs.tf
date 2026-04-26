output "ecr_repository_url" {
  value = module.ecr.ecr_repository_url
}

output "alb_dns_name" {
  value = module.blue_green.alb_dns_name
}

output "tg_blue_arn" {
  value = module.blue_green.tg_blue_arn
}

output "tg_green_arn" {
  value = module.blue_green.tg_green_arn
}

output "sonarqube_url" {
  value = "http://${module.sonarqube.sonarqube_public_ip}:9000"
}
