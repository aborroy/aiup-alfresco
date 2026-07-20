---
name: aiup-alfresco
description: Runs AIUP Alfresco extension workflow steps (requirements, scaffold, content-model, web-scripts, docker-compose, test, and more). Use when the user asks to execute an AIUP command or develop Alfresco extensions following AGENTS.md.
---

# AIUP Alfresco — command orchestrator

Invoke any AIUP step with `/<command>` in Agent chat (Cursor 2.4+), or open `commands/<name>.md` directly.

## Before any step

1. Read `AGENTS.md`.
2. Open `commands/<name>.md` for the requested step (or type `/<name>`).
3. Apply referenced skills under `.cursor/skills/` when the command mentions them.
4. Create or update real files; do not stop at a summary unless the user asked for a plan only.

## Available commands

| Slash command | Description |
|---------------|-------------|
| `/aca-extension` | Scaffold a full ACA/ADW UI extension: plugin.json descriptor, provideExtension() providers function, NgRx actions and effects, Angular standalone components for the requested extension points (page, sidebar, context menu, toolbar), HTTP service, and integration patch instructions for extensions.module.ts, project.json, and app.config.json. |
| `/actions` | Scaffold Alfresco ActionExecuter classes with Spring bean registration. In-Process SDK (Maven) only. |
| `/aikau` | Generate Share Aikau page and dashlet artefacts for legacy Share UI customizations. |
| `/audit` | Generate a custom Alfresco audit application (audit XML + data extractors/generators + enable properties) and optional query Web Script. In-Process SDK (Maven) only. |
| `/behaviours` | Scaffold Alfresco behaviour/policy classes with Spring bean wiring. In-Process SDK (Maven) only. |
| `/bootstrap-loader` | Generate an AbstractModuleComponent data bootstrap loader that creates initial folders, categories, or reference data exactly once per module version. In-Process SDK (Maven) only. |
| `/content-model` | Generate Alfresco content model XML and Spring context file from requirements. |
| `/content-store` | Scaffold a custom Alfresco ContentStore connector (extending AbstractContentStore, optionally wrapping a caching or encrypting store) with its reader/writer, Spring wiring, and unit test. In-Process SDK (Maven) only. |
| `/docker-compose` | Generate a Docker Compose file with full ACS stack. |
| `/events` | Generate an Out-of-Process Spring Boot event listener for Alfresco Java Event API. |
| `/metadata-extractor` | Scaffold a custom Alfresco metadata extractor/embedder (extending AbstractMappingMetadataExtracter) with a properties mapping file, Spring registration, and unit test. In-Process SDK (Maven) only. |
| `/permissions` | Generate custom Alfresco permission groups and permissions (permissionDefinitions.xml extension) plus optional dynamic authorities, Spring registration, and unit test. In-Process SDK (Maven) only. |
| `/repository-patch` | Generate an AbstractPatch repository patch that migrates existing data or structure between module versions, runs exactly once per repository, and is recorded in alf_applied_patch. In-Process SDK (Maven) only. |
| `/requirements` | Gather and structure requirements for an Alfresco extension as user stories with acceptance criteria. |
| `/rest-api` | Generate a modern ACS v1 Public REST API resource (annotation-based @EntityResource / @RelationshipResource with @WebApiDescription) plus model POJO, Spring registration, and unit test. In-Process SDK (Maven) only. |
| `/rule-conditions` | Generate a custom Alfresco rule condition evaluator with parameter definitions, Spring bean registration, and unit test. In-Process SDK (Maven) only. |
| `/scaffold` | Scaffolds one deployable project or a mixed multi-project repository from REQUIREMENTS.md: pom.xml(s), module.properties, module-context.xml, Share-tier base structure, and Spring Boot Application class. Supports Platform JAR (in-process), Share JAR (web-tier), Event Handler (out-of-process), and mixed architectures. Run this first, before /content-model. |
| `/scheduled-jobs` | Generate a cluster-safe Quartz scheduled job with configurable cron expression, separate executer bean, Spring scheduler registration, and unit test. In-Process SDK (Maven) only. |
| `/share-config` | Generate Share share-config-custom.xml (META-INF/), DocLib UI actions, rule-action UI, evaluators, indicators, forms, and related web-extension files for legacy Share UI. |
| `/subsystem` | Scaffold a custom Alfresco subsystem (ChildApplicationContextFactory + default/instance properties) or, in authentication mode, configure a custom authentication chain / external IdP (LDAP, identity-service/OIDC, external). In-Process SDK (Maven) / config. |
| `/surf` | Generate Share Surf extension artefacts for legacy Share pages, components, templates, and extension metadata. |
| `/test` | Generate integration tests for Alfresco extensions using Testcontainers (self-contained, no pre-running ACS required). |
| `/transforms` | Register a custom rendition definition (Platform JAR) and, when no built-in transform covers the required source/target mimetype pair, scaffold a custom Transform Engine (Spring Boot, Out-of-Process). Optionally registers a new MIME type. |
| `/web-scripts` | Generate Alfresco Web Script descriptors, controllers, and FreeMarker templates. In-Process SDK (Maven) only. |
| `/workflow` | Generate Activiti BPMN 2.0 process definition, workflow task content model, Spring bootstrap registration, i18n message bundle, and optional Java task listener. In-Process SDK (Maven) only. |

## Typical order

1. `/requirements` — architecture decision + REQUIREMENTS.md
2. `/scaffold` — project skeleton (requires REQUIREMENTS.md)
3. Feature commands as needed, for example:
   - Platform JAR: `/content-model`, `/behaviours`, `/web-scripts`, `/rest-api`, `/actions`, `/workflow`, `/scheduled-jobs`, `/bootstrap-loader`, `/rule-conditions`, `/repository-patch`, `/permissions`, `/audit`, `/content-store`, `/metadata-extractor`, `/subsystem`, `/transforms`
   - Out-of-process: `/events`
   - Share JAR: `/share-config`, `/surf`, `/aikau`
   - ACA/ADW: `/aca-extension`
4. `/docker-compose` — before integration tests
5. `/test` — last

## Rendered prompt (optional)

```bash
./scripts/aiup-command.sh render --agent cursor <command> [args...]
```

See `CURSOR.md` for hooks, @ references, and troubleshooting.
