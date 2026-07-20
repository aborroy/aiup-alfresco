---
name: event-api-topology-checker
description: Validates ActiveMQ topic names and consumer group patterns against Alfresco event API conventions. Applies to Out-of-Process SDK (Spring Boot) only. Trigger when generating event-driven code with /events.
---


# Event API Topology Checker

Validate **Out-of-Process** event-driven code against Alfresco Java Event API conventions.

> This skill applies exclusively to the **Spring Boot Out-of-Process SDK** (`alfresco-java-sdk`).
> In-Process extensions (behaviours, actions) run inside the ACS JVM and do not use this event bus — use behaviours/policies instead.

## Topic Naming
- Default Alfresco topic: `alfresco.repo.event2`
- Custom topics must not collide with built-in topics
- Consumer group names should follow: `{extension-prefix}.{purpose}`

## Event Types
Valid event types from `org.alfresco.event.sdk.model.v1`:
- `NodeCreatedEvent`, `NodeUpdatedEvent`, `NodeDeletedEvent`
- `ContentCreatedEvent`, `ContentUpdatedEvent`, `ContentDeletedEvent`
- `ChildAssocCreatedEvent`, `ChildAssocDeletedEvent`
- `PeerAssocCreatedEvent`, `PeerAssocDeletedEvent`

## Configuration Validation
- Verify `spring.activemq.broker-url` is set
- Verify event filters match expected node types/aspects
- Warn if no error handling or dead-letter queue is configured

## Output
Report topology issues, naming violations, and missing error handling.
