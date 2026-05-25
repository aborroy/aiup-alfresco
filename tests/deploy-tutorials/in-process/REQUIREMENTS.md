# Requirements: In-Process Deploy Test

## 1. Business Purpose
Validate that an in-process Platform JAR extension (web scripts + content model) can be
built with Maven, deployed inside ACS 26.1 via Docker Compose, and that the registered
web scripts are reachable via the Alfresco REST endpoint.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: deploy-test-inprocess
- **Platform module**: deploy-test-inprocess
- **ACS version**: 26.1
- **Search profile**: Solr (Profile B — community default)

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17, Maven 3.9+
- Docker Compose v2

## 4. User Stories
- As a CI pipeline, the built JAR is mounted into the ACS container and ACS starts successfully.
- As a CI pipeline, a GET request to the custom web script returns HTTP 200.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:doc` extends `cm:content`
  - `sc:isActive` (d:boolean, optional)

## 6. API Requirements
- `GET /api/sc/ping` — returns `{"status":"ok"}`, auth: user, format: json,
  transaction: required, cache: never

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Platform JAR mounted at:
  `/usr/local/tomcat/webapps/alfresco/WEB-INF/lib/deploy-test-inprocess-1.0.0-SNAPSHOT.jar`
- Compose profile: Solr (no OpenSearch dependency for faster startup in CI)

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | compose.yaml (volume mount) | ACS /probes/-ready- returns 200 |
| US-02 | ping.get.desc.xml, ping.get.json.ftl | GET /alfresco/s/api/sc/ping returns 200 |
