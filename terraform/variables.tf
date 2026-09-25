variable "aws_region" {
  description = "Region for the whole stack. Set it in terraform.tfvars (do not commit that file). Subnets use the first two availability zones."
  type        = string
}

variable "project_name" {
  description = "Name prefix for tags and resource names."
  type        = string
  default     = "harbor-tasks"
}

variable "environment" {
  description = "Environment tag (dev/demo)."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR. Must be large enough for the six /24 subnets below."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnets (ALB + NAT), one per AZ."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Two private app subnets (EC2), one per AZ."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_data_subnet_cidrs" {
  description = "Two private data subnets reserved for a future database. No NAT route."
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "app_instance_type" {
  description = "EC2 size for Harbor Tasks. t3.micro is enough for the demo."
  type        = string
  default     = "t3.micro"
}

variable "app_instance_count" {
  description = "How many app instances to register with the ALB (1 or 2). Tasks are stored on local disk, so 2 instances will NOT share the same board until you add a database."
  type        = number
  default     = 1

  validation {
    condition     = var.app_instance_count >= 1 && var.app_instance_count <= 2
    error_message = "app_instance_count must be 1 or 2 in this half-build."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention. Shorter = cheaper."
  type        = number
  default     = 14
}
