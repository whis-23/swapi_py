output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "listener_http_arn" {
  value = aws_lb_listener.http.arn
}

output "listener_test_arn" {
  value = aws_lb_listener.test.arn
}

output "tg_blue_arn" {
  value = aws_lb_target_group.blue.arn
}

output "tg_green_arn" {
  value = aws_lb_target_group.green.arn
}

output "lt_blue_id" {
  value = aws_launch_template.blue.id
}

output "lt_green_id" {
  value = aws_launch_template.green.id
}
