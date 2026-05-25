---
description: "Scaffold Alfresco behaviour/policy classes with Spring bean wiring. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /behaviours — Behaviour/Policy Generator

> **In-Process SDK only** — deploys inside the ACS JVM as a Platform JAR.
> For asynchronous event-driven reactions to repository changes from an external app, use `/events` (Out-of-Process) instead.

Generate Alfresco behaviour classes for synchronous node event handling.

## Input
Read `REQUIREMENTS.md` to identify behaviour requirements and resolve the Platform JAR
project's `Root path` from Section 2 (Project Architecture).

- If Section 2 contains no `Platform JAR` project, stop and explain that `/behaviours`
  only applies to the in-process repository addon project.

## Output Files

### 1. Behaviour Class
`{platform-project-root}/src/main/java/{package}/behaviour/{Name}Behaviour.java`
- Implement appropriate policy interface (`OnCreateNodePolicy`, `OnUpdatePropertiesPolicy`, `OnAddAspectPolicy`, etc.)
- Register behaviour in `init()` method using `PolicyComponent`
- Inject required Alfresco services

### 2. Spring Bean Configuration
Add bean definition to `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/service-context.xml`

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID (e.g. `behaviours`), not the full `module.id` property value (e.g. `com.someco.behaviours`). Derive it as `{platform-artifactId}` from Section 2 of `REQUIREMENTS.md` or from `<artifactId>` in the platform `pom.xml`. **Never use `{groupId}.{artifactId}` as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Use `JavaBehaviour` with `NotificationFrequency.TRANSACTION_COMMIT` (default) or `EVERY_EVENT` where specified
- Bind to specific types/aspects from the content model
- Log at appropriate levels
- Handle transaction context properly
- Never generate behaviours inside the Event Handler project

## SearchService Query Rules

### Rule 1 — Always use AFTS; never use Lucene query language

Every `SearchParameters` object **must** use `SearchService.LANGUAGE_FTS_ALFRESCO`.
`SearchService.LANGUAGE_LUCENE` is deprecated since ACS 6.x, incompatible with Search
Enterprise (Elasticsearch/OpenSearch), and must never appear in generated code.

```java
// CORRECT
SearchParameters sp = new SearchParameters();
sp.setLanguage(SearchService.LANGUAGE_FTS_ALFRESCO);
sp.setQuery("TYPE:\"vc:vendorContract\" AND cm:name:\"foo\"");

// WRONG — old Lucene style, forbidden
sp.setLanguage(SearchService.LANGUAGE_LUCENE);
sp.setQuery("@cm\\:name:\"foo\"");                         // @variable notation — forbidden
sp.setQuery("@{http://…/content/1.0}name:\"foo\"");       // namespace-qualified — forbidden
```

The `@variable` / `@{namespace}property` notation belongs to the Lucene query parser.
In AFTS, reference properties directly by their prefixed name: `prefix:property`.

| Lucene (forbidden) | AFTS equivalent |
|--------------------|-----------------|
| `@cm\\:name:"foo"` | `cm:name:"foo"` |
| `@{http://…/content/1.0}name:"foo"` | `cm:name:"foo"` |
| `TYPE:"cm:content"` | *(same in AFTS — TYPE keyword is shared)* |
| `@vc\\:expiryDate:[MIN TO NOW]` | `vc:expiryDate:[MIN TO NOW]` |

### Rule 2 — Transactional queries require the `=` exact-match prefix

When a behaviour calls `SearchService` with `QueryConsistency.TRANSACTIONAL` (DB-backed, bypasses
Solr), the query syntax for property matching **must** use the `=` exact-match prefix:

```java
// CORRECT — IDENTIFIER/exact-match mode, supported by the DB query engine
"=vc\\:responsibleDepartment:\"IT\""

// WRONG — phrase mode (DEFAULT analysis), throws QueryModelException in ACS 26.1
"vc\\:responsibleDepartment:\"IT\""
```

**Why**: The DB query engine (`DBFTSPhrase`) rejects `DEFAULT` analysis mode and throws
`QueryModelException: Analysis mode not supported for DB DEFAULT`.  The leading `=` forces
`IDENTIFIER` mode, which the DB engine supports for exact property lookups.

This rule applies whenever `QueryConsistency.TRANSACTIONAL` or `QueryConsistency.TRANSACTIONAL_IF_POSSIBLE`
is set on a `SearchParameters` object.

## Behaviour Design: Eligibility-First Pattern

Always resolve whether the behaviour applies to the current node **before** performing any
expensive operation (content streaming, external service calls, acquiring locks).  If the
behaviour is opt-in (e.g. activated by an aspect on a folder, a configuration property, or
a path rule), check eligibility with cheap `NodeService` / `NodeProperties` calls first and
return early when the node is out of scope.

```java
// CORRECT — cheap eligibility guard first
if (!isEligible(nodeRef)) {   // e.g. aspect present? config flag set? node in target path?
    return;
}
doExpensiveWork(nodeRef);     // content I/O, remote calls, locking — only when needed

// WRONG — expensive work done unconditionally for every event in the whole repository
doExpensiveWork(nodeRef);
if (!isEligible(nodeRef)) {
    return;
}
```

Failing to guard early causes every matching node event across the entire repository to pay
the full cost of the behaviour, even when it is not configured for that node or folder.
