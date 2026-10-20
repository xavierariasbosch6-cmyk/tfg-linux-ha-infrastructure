# Engineering roadmap — Linux HA Infrastructure

> **Cloud-cost restriction adopted 20 October 2026:** **0 EUR.** No paid resources, no credit-dependent AWS deployments and no automatic paid-plan upgrades. Optional deployment may use **Oracle Cloud Always Free only after eligibility and quotas are verified**. See [strict zero-cost policy](CLOUD_0_EUR.md). The AWS infrastructure architecture below is a **deferred educational design**, not an authorized deployment.

> **Status: PLANNED.** This document describes the evolution of the June 2026 UOC Final Degree Project. It is a plan, not evidence of implementation. See [README](../README.md) for the validated original lab. Do not interpret the targets or commands below as currently available features.

## Outcome

Turn the completed three-VM academic lab into a **reproducible, observable, fault-tolerant infrastructure engineering portfolio**:

- A reviewer can inspect real source configuration and understand the design decisions.
- A reviewer can run a documented local demo without access to the author's VMs or cloud credentials.
- CI runs automated functional checks in a public GitHub repository.
- A local HA lab demonstrates real load-balancer failover.
- An **optional, cost-controlled** cloud environment remains available independently of the author's desktop and demonstrates cloud-native availability design.
- Test evidence includes commands, success/failure criteria, collected output, and measured recovery times, not merely screenshots of dashboards.

## Baseline — original TFG (COMPLETED IN JUNE 2026, SOURCE IMPORT PENDING)

- Three Ubuntu Server VMs in VMware Workstation: `node1` (`192.168.19.128`), `node2` (`192.168.19.129`), and `lb` (`192.168.19.130`).
- Nginx services on both web nodes; HAProxy HTTP round-robin load balancing.
- Containerized Nginx services on port `8080`; HAProxy configured to route to containers.
- Prometheus, Node Exporter and Grafana monitoring; Bash/cron periodic service checks with logs.
- Reported successful validation of networking, balancing, containers, monitoring, and automation.
- **Known limitation:** one HAProxy instance is a single point of failure; all original VMs were hosted locally.

### Immediate task: preserve actual artifacts

Collect and review original HAProxy/Nginx/Netplan files, Docker/Compose definitions, Prometheus configuration, Bash scripts, cron configuration, screenshots and the final project report. Redact credentials, private keys, tokens, host-specific secrets, and unnecessary personal data before publication. Never fabricate historical source artifacts.

## Milestone 1 — Reproducible local demo (PLANNED)

**Goal:** Clone the repository on a clean Linux/Docker machine and run a small representative stack without access to VMware.

Suggested deliverables:
- `deploy/local/compose.yaml`: HAProxy + two distinct Nginx backends; optionally Prometheus/Grafana after core checks work.
- `Makefile` or `scripts/` helper entry points with clear prerequisites.
- Health endpoints, container health checks, functional smoke tests, repeatable clean-up.
- Documentation for `make up`, `make test`, and `make down` **once those commands are implemented**, including expected output.
- GitHub Actions CI performing static analysis and integration tests of this local demo.

**Acceptance test:** From a fresh checkout, bring up the stack; demonstrate successful responses through HAProxy from both backends; stop one backend and verify requests continue via the healthy one; recover it; destroy the demo and leave no stray resources.

## Milestone 2 — Load-balancer failover in VMware (PLANNED)

**Goal:** Remove the single HAProxy failure point in a Linux networking lab.

- Add a second HAProxy VM (`lb2`), keeping `node1` and `node2`.
- Install Keepalived on `lb1` and `lb2` with VRRP and a virtual IP (VIP) in a **compatible shared Layer-2 network**.
- Configure appropriate health scripts so a failed HAProxy process can trigger failover.
- Test primary load balancer outage, service/process failure, recovery, and protection against a split-brain scenario.
- Capture actual transition timing, service interruption, logs, health-check results, and failure-mode limitations.

**Important:** Putting both HAProxy VMs on the *same physical desktop* does **not** protect against desktop failure. For a real **physical-host failover** test, place the load balancers on separate physical hosts with a compatible network, or use an independently hosted architecture. Keepalived VRRP/VIP is not a drop-in cross-cloud or cross-availability-zone solution.

## Milestone 3 — Infrastructure automation (PLANNED)

- Ansible roles/playbooks to provision users, services, Docker runtime, Nginx, HAProxy, and monitoring.
- Secure configuration templating, repeatable executions, linting and idempotence tests.
- Do not commit inventory credentials, SSH private keys, `.env` files, Terraform state or production secrets.

**Acceptance test:** A fresh Linux environment can be configured from documented Ansible playbooks, re-running configuration makes no unintended changes, and tests verify the expected services.

## Milestone 4 — Cloud deployment, optional profile(s) (PLANNED)

Cloud HA should use **cloud-native networking**, not assume the local VRRP/VIP design works across regions or availability zones.

### AWS learning profile — preferred for AWS/DevOps roles

- Use Terraform to create a VPC, public/private subnet layout, security groups and suitable compute/network components.
- Target two independently hosted application backends and an AWS-managed Application Load Balancer with health checks; use at least two Availability Zones **when the account and budget support them**.
- Add CI/CD and restricted access; prefer GitHub OIDC to static AWS credentials where supported.
- Provide `terraform plan`, `apply` and `destroy` instructions, resource inventory, cost estimate and cleanup verification.
- **No assumption of free operation:** an existing account may not be eligible for new-customer credits; load balancers, networking, addresses and data transfer can incur charges. Validate actual quotas/service availability, estimate costs before provisioning and set budgets/alerts. AWS Budgets alerts do not constitute a universal hard spending cap.
- Default to **short-lived demonstration deployments**, not a continuously running environment, unless a separate budget is approved.

### Oracle Cloud Always Free profile — optional low-cost public demo

- Investigate OCI Always Free compute capacity and the included 10 Mbps managed load balancer for a small always-on demonstration.
- Verify available compute shapes, ARM64-compatible container images, eligible resource limits, region availability, quotas, and HA properties.
- Do not claim multi-availability-zone resilience or guaranteed zero cost without validating the actual deployment.
- If free capacity is unavailable, fall back to the locally reproducible demo rather than creating unexpected paid resources.

**Acceptance test:** With cloud resources live, stopping one application backend does not make the endpoint unavailable; logs and monitoring corroborate routing decisions. A physical failure of the author's home desktop must not affect the independently hosted cloud endpoint. Destroying the cloud stack leaves no billable resources for the test environment.

## Milestone 5 — Observability and incident response (PLANNED)

- Prometheus targets and exporters, Grafana dashboards, and actionable alert rules with a documented scope.
- Health checks and structured HTTP/status metrics; runbooks for outage diagnosis and restoration.
- Document objective measurements: time to detect failures, time to recover service, error rate during failover, failure modes and remaining single points of failure.
- Add a small controlled failure-injection test suite. Never claim 'zero downtime' without reproducible evidence.

## Milestone 6 — Portfolio presentation (PLANNED)

- Architecture diagrams: original, local HA, and optional cloud implementation.
- One-page executive summary and concise technical README, plus full documentation.
- Actual configuration/source and a `quickstart`, documented environment variables and safe teardown.
- GitHub Actions result, integration-test instructions, screenshots, a brief demo video, and failure/incident report.
- Version notes clearly separating the **completed 2026 TFG** from extensions done afterward.

## Definition of done

A milestone is marked **COMPLETE** only when real source code/configuration is committed, the implementation has been run, evidence is recorded, instructions can be followed independently, and security/cost risks have been reviewed.

### No fake guarantees

- Multi-backend HTTP load balancing alone is **not** full high availability.
- A cloud managed load balancer does **not** automatically make all components fault-tolerant.
- A working local test does **not** prove cross-host or cross-zone resilience.
- Public GitHub source is not the same as a free always-on hosted service.
- Realistic limitations and failure evidence are part of the engineering deliverable.
