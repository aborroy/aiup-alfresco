# deploy-tutorials

Deployment test harness for `aiup-alfresco`. Covers the full development → packaging →
deployment cycle for each major extension type:

| Scenario | Extension type | What is tested |
|----------|---------------|----------------|
| `in-process` | Platform JAR | Maven build → JAR mounted into ACS → web script reachable |
| `out-of-process` | Spring Boot event handler | Maven build + Docker → event handler connects to ACS/ActiveMQ |
| `transforms` | Platform JAR + custom T-Engine | Maven build + Docker → engine listed in transform-router config |
| `aca-extension` | ACA/ADW UI extension | Angular multi-stage Docker build → ACA serves extension plugin |

---

## Prerequisites

- `docker` and `docker compose` (v2)
- `maven` 3.9+ and Java 17 (for in-process, out-of-process, transforms)
- `claude` CLI in PATH (for generation step)
- Sufficient RAM: ACS stack requires ~6 GB; run scenarios one at a time

---

## Full workflow (generate + deploy + smoke + teardown)

```bash
cd aiup-alfresco/tests/deploy-tutorials

# Step 1: generate all four projects
./generate.sh

# Step 2: deploy, smoke-test, and tear down all scenarios sequentially
./run-all.sh
```

Single scenario:

```bash
./generate.sh in-process
./deploy.sh in-process

# Keep the stack running for manual inspection:
./deploy.sh in-process --no-teardown
```

---

## What each step does

### `generate.sh`

Uses `claude -p --dangerously-skip-permissions` to run the aiup slash commands for each
scenario and write the generated files into `generated/<scenario>/`:

| Scenario | Commands run |
|----------|-------------|
| in-process | `/scaffold` → `/content-model` → `/web-scripts` → `/docker-compose` |
| out-of-process | `/scaffold` → `/events` → `/docker-compose` |
| transforms | `/scaffold` → `/content-model` → `/transforms` → `/docker-compose` |
| aca-extension | `/aca-extension` (standalone — no Platform JAR) |

### `deploy.sh <scenario>`

1. **Build** — `mvn clean package` (Platform JAR/event handler), `docker build` (custom engines)
2. **Up** — `docker compose up -d --build`
3. **Wait** — polls service-specific health endpoints until ready or timeout (default 300s)
4. **Smoke** — runs `<scenario>/smoke.sh` HTTP checks
5. **Teardown** — `docker compose down -v` (skipped with `--no-teardown`)

### Smoke tests

| Scenario | Checks |
|----------|--------|
| in-process | ACS ready probe; `GET /alfresco/s/api/sc/ping` returns 200; `sc:doc` type in ACS dictionary |
| out-of-process | ACS ready probe; event handler `/actuator/health` returns `{"status":"UP"}` |
| transforms | transform-router `/transform/config` returns 200 and contains the custom engine name |
| aca-extension | ACA root `/` returns 200; `assets/plugins/ext-deploy-test.plugin.json` served |

---

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `DEPLOY_TIMEOUT` | `300` | Seconds to wait for services to become healthy |
| `MAVEN_OPTS` | — | Passed through to Maven builds |

---

## Troubleshooting

**ACS does not become healthy within timeout**
Increase `DEPLOY_TIMEOUT=600` or check `docker compose logs alfresco`.
On first run, ACS downloads images and initialises the database — allow 5–8 minutes.

**Maven build fails**
Run `mvn clean package` manually in `generated/<scenario>/` to see the full error.
The most common cause is a missing Alfresco Nexus dependency — check network access.

**ACA build fails**
The `aca-extension` Docker build clones ACA from GitHub and runs `npm ci` — requires
internet access and ~2 GB of disk space. Check the Docker build log for npm errors.

**transform-router does not list the custom engine**
Verify `MARKDOWNENGINE_URL` (or equivalent) is set on the transform-router service in
`generated/transforms/compose.yaml` and that the engine's healthcheck passes.
