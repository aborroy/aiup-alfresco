# Requirements: Transforms Deploy Test

## 1. Business Purpose
Validate that a custom Transform Engine can be built, registered with the ACS 26.1
Transform Router via Docker Compose, and that the `/transform/config` endpoint on the
transform-router shows the custom engine as an available transformer.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process) + Custom Transform Engine (out-of-process)
- **groupId**: com.someco
- **artifactId**: deploy-test-transforms
- **Platform module**: deploy-test-transforms
- **ACS version**: 26.1
- **Search profile**: Solr (Profile B)

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17, Maven 3.9+, Docker Compose v2

## 4. User Stories
- As a CI pipeline, the custom transform engine Docker image builds successfully.
- As a CI pipeline, the transform-router `/transform/config` endpoint lists the custom
  engine's transformerName.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:doc` extends `cm:content`

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Transform and rendition requirements
- **Rendition**: `scPing` — source `text/plain`, target `text/plain` (identity, easy to verify)
- **Engine name**: `scPing`
- **Engine queue**: `scPing-engine-queue`
- No custom MIME types needed
- No custom engine build complexity — use `eclipse-temurin:17-jre-jammy` as runtime image

## 8. Deployment Requirements
- Platform JAR mounted into ACS
- Custom engine built via Dockerfile and added to `transform-router`
- transform-router environment: `SCPING_URL=http://sc-ping-engine:8090`, `TRANSFORMER_QUEUE_SCPING=scPing-engine-queue`
- `shared-file-store` service required for transform pipeline
- Compose uses the Solr profile

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | sc-ping-engine/Dockerfile | Docker build exits 0 |
| US-02 | compose.yaml (transform-router + engine) | GET http://localhost:8095/transform/config contains "scPing" |
