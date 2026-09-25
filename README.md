# Harbor Tasks — Secure 3-tier VPC starter

A portfolio-sized AWS network, not a YouTube clone.

**Harbor Tasks** is a small task tracker. Browsers talk to an **internet-facing Application Load Balancer**. The EC2 instances that run the app live in **private subnets** with **no public IP** and **no SSH**. They reach the internet only through a **NAT Gateway** (for patches, SSM, and logs). Identity is an **IAM instance role**, not access keys in code.

This repo is the **half-build**: custom VPC (2 AZs) + ALB + private app + CloudWatch logs. A database, HTTPS, and auto scaling are documented as next steps — they are not required to demo the architecture.

**Default path: run locally.** Live AWS (`terraform apply`) is optional. NAT Gateway is the costly piece — it bills by the hour. Keep Terraform in the repo for when you are ready to demo the VPC, then destroy the stack.

Read **[DESIGN.md](./DESIGN.md)** for requirements, choices, and tradeoffs. Learning notes (why each AWS box exists, in interview language) live in **[docs/](./docs/)**:

- [Project brief](./docs/project-brief.md)
- [Architecture](./docs/architecture.md)
- [AWS concepts](./docs/aws-concepts.md)
- [Learning path](./docs/learning-path.md)

---

## Architecture (short)

```
You  →  Internet Gateway  →  ALB (public subnets, 2 AZs)
                               ↓  security group: 8080 from ALB only
                         EC2 Harbor Tasks (private app subnet)
                               ↓  outbound
                         NAT Gateway (public subnet)  →  IGW  →  internet
```

Empty **data** subnets sit in both AZs with **no NAT route**, ready for RDS later.

Two-AZ picture and hop-by-hop traffic are in [DESIGN.md](./DESIGN.md).

**Compute choice:** Amazon Linux 2023 on **EC2** (not Fargate). That is the simpler SAA story: instance profile, user data, target groups, SSM.

---

## What works in this half-build

| Piece | In this repo |
| --- | --- |
| Custom VPC, 2 AZs, public + private app + private data subnets | Terraform |
| IGW, one NAT Gateway, route tables | Terraform |
| Security groups (ALB → app only; no port 22) | Terraform |
| ALB HTTP:80 → Gunicorn :8080, health `/health` | Terraform |
| Harbor Tasks UI + JSON API | `app/` |
| IAM instance role (CloudWatch logs + SSM) | Terraform |
| CloudWatch log group + agent on the instance | Terraform |
| Local run without AWS | `app/` |

## Still stubbed (do these after the URL works)

- **RDS / shared storage** — tasks are a JSON file on the instance
- **HTTPS** — listener is HTTP only
- **Auto Scaling Group** — default is one EC2
- **Alarms** — logs exist; no 5xx/CPU alarm
- **Second NAT Gateway** — cheaper now; weaker AZ isolation for outbound

---

## Cost warning (read this)

**NAT Gateway is the expensive part.** AWS charges for every hour it exists, plus data processing. An ALB also bills hourly. A `t3.micro` is small; NAT is not.

- Demo, then **`terraform destroy`**. Do not leave this stack up “for a week to look at later.”
- This half-build uses **one** NAT (not one per AZ) on purpose.
- CloudWatch logs retain **14 days**.

If you only want to click the app, run it locally. That costs nothing.

---

## Run the app locally (no AWS)

Needs Python 3.12+.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements.txt
PORT=43180 python app/app.py
```

Open [http://127.0.0.1:43180](http://127.0.0.1:43180). Add a task. The instance pill will say `local` because you are not on EC2.

```bash
PYTHONPATH=app pytest tests -q
```

---

## Deploy to AWS (optional)

Skip this until you want a live VPC demo. Local Flask is enough to use Harbor Tasks. Terraform is here so you can apply later; it is not required to clone or run the app.

**You need:** an AWS account, credentials on your laptop (`aws configure` or SSO), permission to create VPC/EC2/ALB/IAM/Logs, and [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and set `aws_region` to your AWS region (the example uses the placeholder `changeme`).
2. Apply:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

3. Wait **3–5 minutes** after apply. User data installs Python and starts Gunicorn. The target group stays unhealthy until `/health` returns 200.
4. Open the `alb_url` output (`http://<alb dns>`). There is no HTTPS yet; the browser may warn about that — it is expected.
5. Optional, to shell onto the private box (no SSH):

```bash
aws ssm start-session --target "$(terraform output -raw instance_ids | tr -d '[]" ' | awk '{print $1}')"
```

Easier: copy the instance id from `terraform output instance_ids`, then `aws ssm start-session --target i-...`.

6. When you stop for the day:

```bash
terraform destroy
```

**If apply fails on IAM:** your user needs `iam:PassRole` and the ability to create the instance profile. **If the target never becomes healthy:** check the log group `/aws/ec2/harbor-tasks` (bootstrap stream) and the instance’s security group (8080 from the ALB SG only).

---

## App endpoints

| Path | Purpose |
| --- | --- |
| `GET /` | Task board |
| `GET /health` | ALB health check |
| `GET /api/info` | Instance id / AZ (or `local`) |
| `GET/POST /api/tasks` | List / create |
| `PATCH/DELETE /api/tasks/<id>` | Update / delete |

---

## Repo layout

```
app/           Flask app, templates, static files
tests/         API and page tests (no AWS)
terraform/     VPC, SG, ALB, EC2, IAM, CloudWatch
docs/          Learning brief, architecture, AWS concepts, path
DESIGN.md      Requirements, choices, tradeoffs
```
