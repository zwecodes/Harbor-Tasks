resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = var.log_retention_days
}
