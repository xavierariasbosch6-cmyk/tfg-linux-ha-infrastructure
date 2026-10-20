# Test evidence — Local Docker Compose deployment

**Date:** 2026-10-20  
**Source:** Manual test performed by the project owner inside the original `node2` Ubuntu VM; observed in the terminal output shared for review. Supporting CI validation is available separately.

## Environment

- Ubuntu Server 24.04, existing VMware guest with hostname `node2`.
- Docker Engine 29.1.3 (Ubuntu package).
- Docker Compose v2.40.3 (Ubuntu package).
- Source: current `main` branch of this repository, directory `deploy/local`.
- Services deployed by this demo: `lb` (HAProxy), `node1` (Nginx), `node2` (Nginx). These are **Docker containers inside the VM**, not the similarly named original three VMs.

## Execution and results

### Deploy

```bash
git pull --ff-only
sudo docker compose -f deploy/local/compose.yaml up -d --wait
```

Observed output: Docker network `tfg-linux-ha-demo_internal` created; all three containers displayed **Healthy**.

### Traffic distribution

```bash
for i in {1..6}; do curl -sI http://127.0.0.1:8080/ | grep -i x-backend-node; done
```

Observed six consecutive response headers:

```text
x-backend-node: node1
x-backend-node: node2
x-backend-node: node1
x-backend-node: node2
x-backend-node: node1
x-backend-node: node2
```

**PASS:** HAProxy distributed requests to both Nginx backends in round-robin fashion.

### Failure and recovery test

```bash
sudo bash scripts/test_local.sh
```

Output excerpts (reported by the script):

```text
PASS: HAProxy routed traffic to both backends
PASS: node2 handles all tested requests after detection of node1 failure
PASS: node1 rejoined HAProxy
ALL TESTS PASSED
```

**PASS:** When the `node1` container stopped, tested requests continued to reach `node2` after health-check convergence. After restarting the stopped container, `node1` rejoined the backend pool.

## CI verification

[GitHub Actions run #1](https://github.com/xavierariasbosch6-cmyk/tfg-linux-ha-infrastructure/actions/runs/39478467333) also **completed successfully** on 2026-10-20 with Compose configuration validation, container startup, integration tests, and cleanup.

## Important boundaries

- **This is a single-host container demo.** It does not yet implement dual load balancers, Keepalived, multi-host availability, or any cloud deployment.
- The test waits after stopping one backend. It does **not** prove zero failed requests during detection or record a measured recovery time.
- The test reports service behavior in a particular run, not indefinite availability or performance benchmarks.
- The original VMware service configuration remains separate from this new reproducible demo.
- The manual output was reviewed from the project owner's shared terminal screenshot; the raw image is **not** currently committed to GitHub.

## Next engineering goal

Extend this base with real monitoring and failure measurements; then build and test a two-HAProxy/Keepalived VRRP lab on a supported L2 network. Keep the public demonstration cost-free and clearly identify any remaining single points of failure.
