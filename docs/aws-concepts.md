# AWS concepts (short cards)

Use these while you click through Terraform or the console. Each card is **what / why / interview tip**.

Related: [Project brief](./project-brief.md) · [Architecture](./architecture.md) · [Learning path](./learning-path.md)

---

## VPC (Virtual Private Cloud)

**What:** Your own private network in AWS. Ours is `10.0.0.0/16`.

**Why:** The default VPC is fine for experiments. A portfolio project shows you *chose* CIDRs, subnets, and gateways.

**Interview tip:** A VPC is regional. Subnets are in one Availability Zone each. “Multi-AZ” means *more than one subnet, each in a different AZ*.

---

## Subnet

**What:** A slice of the VPC CIDR in **one AZ**. Public vs private is not a checkbox — it is **routing**.

**Why:** Public subnets have a route to an Internet Gateway. Private ones do not (they may use NAT instead). We keep ALB/NAT public, app private, data more private.

**Interview tip:** “Public subnet” means *resources can have public IPs and a default route to the IGW*. An EC2 in a public subnet with *no* public IP still cannot be reached from the internet.

---

## Internet Gateway (IGW)

**What:** The door between the VPC and the public internet.

**Why:** The ALB is internet-facing. Without an IGW and a public route, nobody outside AWS can hit it.

**Interview tip:** Attach one IGW per VPC. You do not put an IGW “in” a subnet. Route tables *point* at it.

---

## NAT Gateway

**What:** A managed translator in a **public** subnet. Private instances use it to start outbound connections (updates, APIs).

**Why:** Our EC2 has no public IP. It still needs to install packages and talk to CloudWatch/SSM.

**Interview tip:** NAT is **not** a firewall for inbound. Inbound to the app goes **ALB → private IP**. NAT Gateways are billed **per hour + per GB** — often the largest line item in a student VPC. Always mention `terraform destroy`. One NAT is a cost choice; two NATs (one per AZ) is an HA choice.

---

## Security group (SG)

**What:** Stateful virtual firewall on a network interface. You allow traffic; everything else is denied.

**Why:** This is how we say “only the load balancer may talk to port 8080.”

**Interview tip:** Security groups **reference other security groups** (ALB SG → app SG). That is better than hard-coding ALB IPs. SGs are *stateful* (reply traffic is allowed automatically). NACLs are *stateless* and subnet-wide — default NACLs are enough for this project.

---

## ALB (Application Load Balancer)

**What:** A Layer-7 load balancer. It reads HTTP, checks `/health`, and spreads requests across healthy targets.

**Why:** Users hit a stable DNS name. Instances can die and be replaced. The app stays in private subnets.

**Interview tip:** ALB needs **at least two public subnets in different AZs**, even if you have one instance. Target type **instance** vs **IP** matters for ECS later; we use instance. HTTP:80 now; HTTPS needs an ACM certificate on a 443 listener.

---

## IAM (roles, not keys)

**What:** Identity and Access Management. Users, roles, policies.

**Why:** The EC2 box must write logs and answer SSM. We attach a **role** (instance profile). We do **not** paste `AWS_ACCESS_KEY_ID` into `app.py`.

**Interview tip:** Keys in code get leaked. Roles are temporary credentials from the instance metadata service (IMDSv2). Least privilege: this role can put logs and use SSM — it cannot delete the VPC.

---

## CloudWatch

**What:** Metrics, logs, and alarms. This half-build uses a **log group** and the CloudWatch Agent on EC2.

**Why:** If the page is blank, you need logs. If you go to production, you add alarms on 5xx and unhealthy hosts.

**Interview tip:** Logs are not the same as metrics. `/health` failing shows up as ALB *unhealthy host* metric. App exceptions show up in the log group `/aws/ec2/harbor-tasks`. Retention (we use 14 days) is a cost control.

---

## Extra cards you will bump into

### Availability Zone (AZ)

One data-center cluster in a region. Two AZs = survive one AZ failure *if* you actually run capacity in both (we only *network* both in the half-build).

### EC2 instance profile

The wrapper that lets EC2 assume an IAM role. In Terraform you attach `iam_instance_profile`.

### SSM Session Manager

Replaces SSH. Port 22 stays closed. You need: agent on the AMI (Amazon Linux has it), instance role, and outbound to SSM (via NAT or VPC endpoints).

### Target group + health check

ALB only routes to instances that return 200 on `/health`. A broken deploy becomes “unhealthy,” not a mystery timeout.
