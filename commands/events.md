---
description: "Generate an Out-of-Process Spring Boot event listener for Alfresco Java Event API."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[event type or description]"
---

# /events — Out-of-Process Event Listener Generator

Generate a Spring Boot Out-of-Process application that consumes Alfresco repository events via ActiveMQ.

`/scaffold` must run first. This command augments the existing Event Handler project; it must not
invent a second project layout or merge event-listener code into the Platform JAR project.

## When to use
Use this command for **asynchronous, reactive integrations**: notifications, external system sync, workflow triggers based on content changes.

Do NOT use for:
- Synchronous content validation → use `/behaviours` (In-Process)
- REST API exposure → use `/web-scripts` (In-Process)
- On-demand triggered logic → use `/actions` (In-Process)

## Input
Read `REQUIREMENTS.md` to identify event-driven integration requirements and resolve the
Event Handler project's `Root path` from Section 2 (Project Architecture).

- If Section 2 contains no `Event Handler` project, stop and explain that `/events` only applies
  to an out-of-process Spring Boot project.
- If Section 2 contains both Platform JAR and Event Handler projects, write files only under the
  Event Handler `Root path` (typically `{name}-events/`), never under the Platform JAR module or
  the aggregator root.

## Output Files

### 1. Spring Boot Application
`{event-project-root}/src/main/java/{package}/{Name}Application.java`
- Expected to exist already from `/scaffold`; create only if missing
- `@SpringBootApplication`

### 2. Event Handler
`{event-project-root}/src/main/java/{package}/handler/{Name}EventHandler.java`
- Annotate with `@AlfrescoEventListener`
- Filter by node type or aspect where applicable
- Log at `INFO` level on successful processing; `ERROR` on failure
- Configure a dead-letter queue for error handling

### 3. Application Properties
`{event-project-root}/src/main/resources/application.properties`
```properties
spring.activemq.broker-url=${SPRING_ACTIVEMQ_BROKER_URL:tcp://localhost:61616}
spring.activemq.user=${SPRING_ACTIVEMQ_USER}
spring.activemq.password=${SPRING_ACTIVEMQ_PASSWORD}
alfresco.events.defaultExchangeName=alfresco.repo.event2
```
- Expected to exist already from `/scaffold`; update only if required properties are missing

### 4. POM
`{event-project-root}/pom.xml` with parent:
```xml
<parent>
    <groupId>org.alfresco</groupId>
    <artifactId>alfresco-java-sdk</artifactId>
    <version>7.2.0</version>
</parent>
```
- Expected to exist already from `/scaffold`; update only if the event starter dependency or related build config is missing
- Include `alfresco-java-event-api-spring-boot-starter` with version `7.2.0` — this artifact is **not** in the `alfresco-java-sdk` parent BOM; the version must be declared explicitly and must match the SDK parent version.
- All generated `.java` files must include the Apache 2.0 license header — the `alfresco-java-sdk` parent enforces this via `license-maven-plugin:check`.
- Always include the Alfresco public Nexus repository so the starter can be resolved without credentials:
```xml
<repositories>
    <repository>
        <id>alfresco-public</id>
        <url>https://artifacts.alfresco.com/nexus/content/groups/public</url>
    </repository>
</repositories>
```

## Conventions
- `{event-project-root}` is `.` for Event Handler only mode, or `{name}-events/` for Mixed mode
- Consumer group naming: `{prefix}.{purpose}` — e.g. `acme.invoiceProcessor`
- Always configure a dead-letter queue
- Use type/aspect filters to avoid processing unrelated events
- After generation, invoke `event-api-topology-checker` skill
- Never generate Spring Boot event-listener code inside a Platform JAR module or under `src/main/resources/alfresco/module/...`

## Deployment
The Out-of-Process app runs as a **separate service** in `compose.yaml` alongside ACS:
```yaml
{extension-name}:
  build: ./{event-project-root}
  environment:
    SPRING_ACTIVEMQ_USER: ${ACTIVEMQ_USER}
    SPRING_ACTIVEMQ_PASSWORD: ${ACTIVEMQ_PASSWORD}
  depends_on:
    activemq:
      condition: service_healthy
    alfresco:
      condition: service_healthy
```
After generation, run `/docker-compose` to add this service to the stack.
