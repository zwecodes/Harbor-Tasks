data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "app" {
  count = var.app_instance_count

  ami                    = data.aws_ami.al2023.id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.private_app[count.index].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.app.name

  # No public IP. No SSH key. Reach the box with SSM Session Manager.
  associate_public_ip_address = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    log_group_name   = aws_cloudwatch_log_group.app.name
    app_py_b64       = base64gzip(file("${path.module}/../app/app.py"))
    requirements_b64 = base64gzip(file("${path.module}/../app/requirements.txt"))
    index_html_b64   = base64gzip(file("${path.module}/../app/templates/index.html"))
    styles_css_b64   = base64gzip(file("${path.module}/../app/static/styles.css"))
    app_js_b64       = base64gzip(file("${path.module}/../app/static/app.js"))
  })

  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-app-${count.index + 1}"
  }
}
