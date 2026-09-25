# Project brief: Harbor Tasks on a custom VPC

**For:** Zwe Htet Aung (SAA learner, internship portfolio)  
**Choice:** Option 1 — Secure 3-tier web app on a custom VPC  
**Half-done target:** ~29 Sept 2026 is enough. Do not wait for “perfect.”

Related: [Architecture](./architecture.md) · [AWS concepts](./aws-concepts.md) · [Learning path](./learning-path.md)

---

## What we are building

A small **task tracker** named **Harbor Tasks**. You reach it through a public Application Load Balancer (ALB). The app servers sit in **private subnets**. They have no public IP. You cannot SSH to them from the internet.

That is the whole story you will tell in an interview:

> I put the app where the internet cannot hit it. The load balancer is the only front door. Security groups decide who may talk to whom.

This is **not** a YouTube clone and **not** a click-through of the AWS console wizard. You own the network diagram.

The runnable starter lives in the git repo (`README.md`, `DESIGN.md`, `terraform/`, `app/`). These store docs teach the *why*. The repo is the *what you deploy*.

---

## Goals

1. **Learn by designing.** You can explain every box: VPC, subnet, IGW, NAT, SG, ALB, IAM role, CloudWatch log group.
2. **Show a real page.** `/` is a working task board. `/health` is what the ALB checks. `/api/tasks` is a small JSON API.
3. **Stay cheap enough to finish.** One NAT Gateway is the expensive piece. Destroy the stack when you are not demoing.
4. **Write like an architect.** `DESIGN.md` in the repo records choices and tradeoffs — that is what recruiters actually read.

---

## Half scope (this starter — ship this first)

| Piece | Status in the starter |
| --- | --- |
| Custom VPC, **2 AZs** | Built in Terraform |
| Public + private **app** subnets | Built |
| Private **data** subnets (empty, for later RDS) | Built, no database yet |
| Internet Gateway + **one** NAT Gateway | Built (see cost warning) |
| Security groups: ALB → app only | Built |
| Internet-facing ALB → EC2 in private subnet | Built |
| Real app (Harbor Tasks) behind the ALB | Built |
| IAM **instance role** (no access keys in code) | Built |
| SSM Session Manager (no SSH port) | Built |
| CloudWatch log group + agent shipping app logs | Built |
| Architecture notes + diagram | `DESIGN.md` + [architecture.md](./architecture.md) |

**Half done means:** `terraform apply` produces a URL. You open it. You add a task. You can point at the diagram and walk traffic hop by hop.

---

## Full scope (later — do not block Sept 29)

Documented as “next” in the repo, not required to call this a portfolio piece:

- **RDS** (or DynamoDB) in the data subnets so two app boxes share the same tasks
- **HTTPS** (ACM certificate + listener 443)
- **Auto Scaling Group** instead of a single EC2
- CloudWatch **alarms** (ALB 5xx, CPU, unhealthy hosts)
- Second NAT Gateway (HA for outbound) or VPC endpoints to cut NAT cost
- Custom domain (Route 53)

---

## What we deliberately skipped

- **Fargate / ECS.** EC2 is simpler for SAA study (instance role, user data, target groups).
- **Long-lived access keys in the app.** The instance uses a role. Your laptop uses your AWS CLI profile.
- **Copying a tutorial VPC CIDR without understanding it.** Ours is `10.0.0.0/16` with named tiers. Learn it in [architecture.md](./architecture.md).

---

## How to use these docs

1. Skim this brief (you are here).
2. Read [architecture.md](./architecture.md) once, slowly, with the mermaid diagram.
3. Use [aws-concepts.md](./aws-concepts.md) as flashcards (what / why / interview tip).
4. Build with [learning-path.md](./learning-path.md) and the repo `README.md`.
