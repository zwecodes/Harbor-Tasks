output "alb_dns_name" {
  description = "Open http://THIS in a browser. There is no HTTPS listener yet."
  value       = aws_lb.app.dns_name
}

output "alb_url" {
  description = "Convenience HTTP URL for the task tracker."
  value       = "http://${aws_lb.app.dns_name}"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  value = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "Empty data-tier subnets. Use these later for RDS."
  value       = aws_subnet.private_data[*].id
}

output "instance_ids" {
  description = "Private EC2 instances. Use with: aws ssm start-session --target ID"
  value       = aws_instance.app[*].id
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.app.name
}

output "nat_gateway_warning" {
  description = "Cost reminder — NAT is billed while it exists."
  value       = "NAT Gateway is running. Destroy this stack when you are not demoing (terraform destroy)."
}
