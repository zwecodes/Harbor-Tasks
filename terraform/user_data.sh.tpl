#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/harbor-bootstrap.log) 2>&1

dnf install -y python3 python3-pip amazon-cloudwatch-agent gzip

install -d -m 0755 /opt/harbor/templates /opt/harbor/static /var/lib/harbor-tasks /var/log/harbor-tasks

printf '%s' '${app_py_b64}' | base64 -d | gzip -dc > /opt/harbor/app.py
printf '%s' '${requirements_b64}' | base64 -d | gzip -dc > /opt/harbor/requirements.txt
printf '%s' '${index_html_b64}' | base64 -d | gzip -dc > /opt/harbor/templates/index.html
printf '%s' '${styles_css_b64}' | base64 -d | gzip -dc > /opt/harbor/static/styles.css
printf '%s' '${app_js_b64}' | base64 -d | gzip -dc > /opt/harbor/static/app.js

python3 -m venv /opt/harbor/venv
/opt/harbor/venv/bin/pip install --upgrade pip
/opt/harbor/venv/bin/pip install -r /opt/harbor/requirements.txt

cat >/etc/systemd/system/harbor-tasks.service <<'UNIT'
[Unit]
Description=Harbor Tasks (Gunicorn)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/harbor
Environment=HARBOR_DATA=/var/lib/harbor-tasks/tasks.json
Environment=PORT=8080
ExecStart=/opt/harbor/venv/bin/gunicorn --bind 0.0.0.0:8080 --workers 2 --access-logfile /var/log/harbor-tasks/app.log --error-logfile /var/log/harbor-tasks/app.log app:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now harbor-tasks

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CWJSON
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/harbor-tasks/app.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/app",
            "retention_in_days": 14
          },
          {
            "file_path": "/var/log/harbor-bootstrap.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/bootstrap",
            "retention_in_days": 14
          }
        ]
      }
    }
  }
}
CWJSON

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
