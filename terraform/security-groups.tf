resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "Internet to ALB on HTTP. HTTPS is a later step."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Public HTTP"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward HTTP to the app instances"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app"
  description = "App instances: only the ALB may connect. No SSH."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "ALB to Gunicorn"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.alb.id
}

# Outbound is open so dnf, SSM, and CloudWatch work through the NAT Gateway.
# Tightening egress (443/53 only, or VPC endpoints) is a good follow-up.
resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "Outbound via NAT (patches, SSM, logs)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Placeholder for a future database. Nothing uses it in the half-build.
resource "aws_security_group" "data" {
  name        = "${var.project_name}-data"
  description = "Future RDS/Aurora. Empty inbound until you add a database."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-data-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "data_none_open" {
  security_group_id = aws_security_group.data.id
  description       = "Allow VPC-local replies later; keep default deny inbound"
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}
