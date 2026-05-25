# Requirements: Maven SDK Baseline

## 1. Business Purpose
Demonstrate a minimal working Alfresco Platform JAR extension that can be built and
deployed to ACS 26.1. No custom content model, behaviours, or actions — this is a
baseline scaffold only.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: maven-sdk-baseline
- **Platform module**: maven-sdk-baseline-platform
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As a developer, I can build the extension with `mvn clean package`.

## 5. Content Model Requirements
None.

## 6. API Requirements
None.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Platform JAR mounted into ACS container.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | pom.xml | build |
