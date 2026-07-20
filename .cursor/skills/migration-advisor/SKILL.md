---
name: migration-advisor
description: Detects deprecated Alfresco API usage and suggests modern equivalents. Trigger when analysing existing Alfresco extension code.
---


# Migration Advisor

Scan Alfresco extension code for deprecated API usage and suggest modern replacements.

## Deprecated Patterns

| Deprecated | Replacement | Since |
|-----------|-------------|-------|
| `ServiceRegistry.getNodeService()` | `@Autowired NodeService` | SDK 4.x+ |
| `AuthenticationUtil.setFullyAuthenticatedUser()` | `AuthenticationUtil.runAs()` | SDK 4.x+ |
| Direct Hibernate session access | `NodeService` / `ContentService` | Always |
| AMP packaging with no third-party library deps | JAR packaging | SDK 4.2+ |
| `AbstractLifecycleBean` for bootstrap | `@PostConstruct` / `ApplicationReadyEvent` | Spring Boot 3.x |
| Alfresco Explorer (JSF) customizations | ACA/ADW extensions | ACS 6.0+ |
| CMIS 1.0 | CMIS 1.1 or REST API v1 | ACS 5.2+ |
| Lucene query syntax | AFTS or CMIS query | ACS 4.0+ |

## Output
For each deprecated usage found, report: file, line, deprecated API, suggested replacement, and migration effort estimate (trivial/moderate/significant).
