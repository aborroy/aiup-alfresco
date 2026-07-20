---
name: docker-compose-healthcheck-injector
description: Ensures every service in a Docker Compose file has a healthcheck block and depends_on uses condition: service_healthy. Trigger when generating or editing compose.yaml.
---


# Docker Compose Healthcheck Injector

Validate and fix Docker Compose files for Alfresco deployments.

## Required Services
Verify these services are present (when applicable):
- `alfresco` — ACS repository
- `postgres` — database
- `activemq` — message broker
- `transform-core-aio` or individual transform services
- `search` — Solr or Elasticsearch
- `share` — (optional, if Share UI is used)

## Healthcheck Rules
Every service must have a `healthcheck` block with:
- `test` — appropriate health endpoint or command
- `interval` — recommended 30s
- `timeout` — recommended 10s
- `retries` — recommended 3
- `start_period` — recommended 60s for Alfresco, 30s for others

## Dependency Rules
- `depends_on` must use `condition: service_healthy` (not just service name)
- `alfresco` depends on `postgres` and `activemq`
- `share` depends on `alfresco`
- `search` depends on `alfresco` (for Solr) or is independent (Elasticsearch)

## Known Healthcheck Endpoints
- Alfresco: `curl -f http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-`
- Share: `curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/share/ | grep -qE '^[23]'`
- ActiveMQ: `curl -sf -u $${ACTIVEMQ_USER:-admin}:$${ACTIVEMQ_PASSWORD:-admin} http://localhost:8161/admin/ > /dev/null`
- PostgreSQL: `pg_isready -d alfresco -U alfresco`
- Solr *(Search Services)*: `curl -f -H "X-Alfresco-Search-Secret: $${SOLR_ALFRESCO_SECRET}" http://localhost:8983/solr/alfresco/admin/ping`
- OpenSearch / Elasticsearch *(Search Enterprise)*: `curl -s http://localhost:9200/_cluster/health | grep -q 'green\|yellow'`
- Transform: `curl -f http://localhost:8090/ready`

## Share Healthcheck — known bad patterns

**FLAG as ERROR** any Share healthcheck that uses a path other than `/share/`:

| Bad pattern | Why it fails |
|-------------|-------------|
| `http://localhost:8080/share/page/home` | `/page/home` does not exist in Share 26.x — Spring Surf throws a 500 `Could not resolve view 'home'`; the container stays `health: starting` forever and blocks dependent services (proxy) |
| `http://localhost:8080/share/page/dashboard` | Same issue — page routes are user-session-dependent |

**Correct pattern**: accept any 2xx or 3xx from the Share root (it redirects to the login page):
```yaml
test: ["CMD-SHELL", "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/share/ | grep -qE '^[23]'"]
```

## Output
List all missing healthchecks and incorrect dependencies. Provide corrected YAML blocks.
