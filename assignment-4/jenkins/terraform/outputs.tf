output "controller_public_ip" {
  description = "Jenkins controller public IP — access at http://<ip>:8080"
  value       = aws_instance.jenkins_controller.public_ip
}

output "agent_private_ip" {
  description = "Jenkins agent private IP — used as SSH host in node config"
  value       = aws_instance.jenkins_agent.private_ip
}

output "agent_instance_profile_arn" {
  description = "IAM instance profile ARN attached to the agent"
  value       = aws_iam_instance_profile.agent_profile.arn
}

output "agent_sg_id" {
  description = "Agent security group ID — needed to grant SonarQube access"
  value       = aws_security_group.jenkins_agent_sg.id
}
