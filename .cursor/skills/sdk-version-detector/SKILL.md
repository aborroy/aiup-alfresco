---
name: sdk-version-detector
description: Reads pom.xml, detects which Alfresco SDK is in use (In-Process Maven SDK or Out-of-Process Spring Boot SDK), and adjusts generated code accordingly. Trigger when generating Java code for Alfresco extensions.
---


# SDK Version Detector

Detect which Alfresco SDK the project uses and report which code generation patterns apply.

## Detection Logic

1. Search for `pom.xml` in the project root and submodules
2. Check `<parent>` `<artifactId>`:
   - `alfresco-sdk-aggregator` → **In-Process SDK** (Maven)
   - `alfresco-java-sdk` → **Out-of-Process SDK** (Spring Boot)
3. If neither parent is found, check for `alfresco-java-event-api-spring-boot-starter` dependency → Out-of-Process
4. If still unclear, check for `alfresco.platform.version` or `acs.version` properties → In-Process

## SDK Types

### In-Process SDK (Maven SDK `alfresco-sdk-aggregator`)
Deploys as a **Platform JAR or AMP inside the ACS JVM**.

| SDK Version | ACS Version | Java | Spring | Patterns |
|-------------|-------------|------|--------|----------|
| 4.x (≤4.11) | 6.x–7.x | 11 | 5.x | Legacy `ServiceRegistry`, XML-only config |
| 4.x (4.12+) | 25.x–26.1 | 17+ | 6.x/Boot 3.x | Web Scripts, XML for integration points, Java config for internal wiring |

Use for: **behaviours, web scripts, actions, content model bootstrap** — anything that must run inside the Alfresco JVM.

### Out-of-Process SDK (Spring Boot SDK `alfresco-java-sdk`)
Runs as a **separate Spring Boot application** outside ACS, connected via ActiveMQ and REST.

| SDK Version | ACS Version | Java | Spring Boot | Patterns |
|-------------|-------------|------|-------------|----------|
| 7.x | 25.x–26.1 | 17+ | 3.x | `@AlfrescoEventListener`, standard Spring Boot `@Configuration` |

Use for: **event listeners, external integrations, async processing** — anything that reacts to repository events over ActiveMQ.

## Output

Report:
- Extension type: **In-Process** or **Out-of-Process**
- Detected SDK and version
- Detected ACS version
- Java version requirement
- For In-Process: whether to use XML or Java-based Spring configuration
- For Out-of-Process: confirm event API and ActiveMQ configuration patterns
- Any version-specific warnings
