# Learning path (build this repo in order)

Do the steps in order. After each step you should be able to *say* what changed, not only *see* that Terraform went green.

Related: [Project brief](./project-brief.md) · [Architecture](./architecture.md) · [AWS concepts](./aws-concepts.md)

Repo files to keep open: `README.md`, `DESIGN.md`, `terraform/`.

---

## 0. Before AWS (30–45 min)

1. Read the [project brief](./project-brief.md) and [architecture](./architecture.md) once.
2. Run the app **on your laptop** (`README.md` local section). Click add / complete / delete. This is the same process that will sit behind the ALB.
3. Flashcard the eight services in [aws-concepts.md](./aws-concepts.md).

**Checkpoint:** You can draw IGW vs NAT from memory.

---

## 1. VPC skeleton (the network only)

Read `terraform/vpc.tf` while you apply, or apply with targets if you like to go slow:

- VPC + two AZs of public / app / data subnets
- Internet Gateway + public routes
- One NAT Gateway + private **app** routes
- Data subnets: local routes only

**Checkpoint:** In the console, a public subnet’s route table shows `0.0.0.0/0 → igw-…`. An app subnet shows `0.0.0.0/0 → nat-…`. A data subnet does **not**.

---

## 2. Security groups (who may talk)

Read `terraform/security-groups.tf`.

**Checkpoint:** App SG inbound is **only** 8080 from the ALB SG. There is no `:22`.

---

## 3. IAM role + CloudWatch log group

Read `terraform/iam.tf` and `terraform/cloudwatch.tf`.

**Checkpoint:** You can explain “the instance role is not my AWS user.”

---

## 4. ALB + EC2 (the working path)

Read `terraform/alb.tf`, `terraform/ec2.tf`, and `terraform/user_data.sh.tpl`.

Apply the rest. Wait for the target group to go **healthy** (user data installs Python; this can take several minutes). Open the `alb_dns_name` output.

**Checkpoint:** Browser shows Harbor Tasks. `/health` returns JSON. The UI footer reminds you the instance is private. Optional: `aws ssm start-session` using the `instance_id` output.

---

## 5. Write your story (portfolio)

Fill nothing in with lorem. In your own words, add 5–10 lines to `DESIGN.md` under “What I would change”:

- Why one NAT
- Why EC2 not Fargate
- Why JSON file not RDS yet
- What fails if AZ-a dies

**Checkpoint:** You can talk for three minutes with only the mermaid diagram on screen.

---

## 6. Destroy (required habit)

NAT + ALB cost money while they exist. Run `terraform destroy` when you stop for the day unless you are okay with the bill.

**Checkpoint:** Console shows the VPC gone. Next apply is a clean rebuild.

---

## After Sept 29 (full scope, one item at a time)

Pick **one** per study weekend. Details live in repo `DESIGN.md`.

1. RDS PostgreSQL in data subnets; app SG → db SG on 5432; stop using the JSON file.
2. ACM certificate + HTTPS listener; redirect 80 → 443.
3. Launch template + Auto Scaling Group (one instance per AZ).
4. Alarms: ALB `HTTPCode_Target_5XX_Count`, unhealthy hosts, NAT bytes.
5. VPC endpoints for SSM/ECR/logs to shrink NAT traffic — or a second NAT.

---

## Exam link (SAA)

When a practice question says “web tier in public, app/db private” or “users must not connect directly to EC2,” this project is the answer you have already built. Re-read [architecture.md](./architecture.md) the night before you sit the exam.
