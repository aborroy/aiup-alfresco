# Requirements: Out-of-Process Deploy Test

## 1. Business Purpose
Validate that a Spring Boot Out-of-Process event listener can be built, started alongside
ACS 26.1 via Docker Compose, and that it successfully connects to ActiveMQ and registers
its consumer group. The Spring Boot app exposes an Actuator health endpoint.

## 2. Project Architecture
- **Extension type**: Event Handler only (out-of-process Spring Boot)
- **groupId**: com.someco
- **artifactId**: deploy-test-outofprocess
- **Event Handler module**: deploy-test-outofprocess
- **ACS version**: 26.1
- **Search profile**: Solr (Profile B)

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17, Maven 3.9+
- Docker Compose v2

## 4. User Stories
- As a CI pipeline, the Spring Boot event handler JAR is built and the Docker image starts.
- As a CI pipeline, the event handler's Actuator health endpoint returns `{"status":"UP"}`.

## 5. Content Model Requirements
None.

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Event handler requirements
- Listen to `NodeCreatedEvent` on the default topic `alfresco.repo.event2`
- Log node type and ID at INFO level on each event
- Consumer group: `sc.deployTest`
- Dead-letter queue: `sc.deployTest.DLQ`

## 8. Deployment Requirements
- Event handler built via `mvn package` and run as a Docker Compose service
- Exposes Spring Boot Actuator at port 8080 (`/actuator/health`)
- Depends on `activemq` and `alfresco` with `condition: service_healthy`
- Compose uses the Solr search profile

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | Dockerfile (event handler), compose.yaml | Docker container starts |
| US-02 | application.properties (actuator), compose.yaml | GET http://localhost:9090/actuator/health returns {"status":"UP"} |
