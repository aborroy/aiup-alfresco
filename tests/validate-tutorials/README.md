# validate-tutorials

Static validation harness that checks `aiup-alfresco` generates structurally correct
artefacts for each `alfresco-developer-series` tutorial pattern.

## How it works

1. Each `scenarios/<scenario>/REQUIREMENTS.md` describes the equivalent of a tutorial extension.
2. You run the appropriate slash commands in Claude Code to generate artefacts.
3. You copy (or generate in-place into) `generated/<scenario>/`.
4. `run-all.sh` checks all populated scenarios; empty directories are reported as SKIP.

## Populating a scenario

Open Claude Code in a working directory, copy the scenario REQUIREMENTS.md there, then run:

| Scenario | Commands to run |
|----------|----------------|
| maven-sdk-baseline | `/scaffold` |
| content-types | `/scaffold` → `/content-model` |
| actions | `/scaffold` → `/content-model` → `/actions` |
| behaviours | `/scaffold` → `/content-model` → `/behaviours` |
| web-scripts | `/scaffold` → `/content-model` → `/web-scripts` |
| workflows | `/scaffold` → `/content-model` → `/workflow` |

Copy the generated project tree into the matching `generated/<scenario>/` directory.

## Running checks

```bash
# All scenarios (SKIP if not yet generated):
./run-all.sh

# Single scenario:
./run-scenario.sh content-types

# Custom generated directory:
./run-scenario.sh content-types /path/to/my/generated/project
```

## What is checked

Every scenario verifies:
- A `pom.xml` uses `alfresco-sdk-aggregator` as parent (SDK 4.15.0)
- `module.properties` exists with `module.id` and `module.version`
- `module-context.xml` exists and imports at least one sub-context

Additional checks per scenario:

| Scenario | Extra checks |
|----------|-------------|
| content-types | `content-model.xml` well-formed, no `enforced="true"`, `*Model.java` uses `QName.createQName()`, `bootstrap-context.xml` uses `dictionaryModelBootstrap` |
| actions | content-types checks + `*ActionExecuter.java` extends `ActionExecuterAbstractBase`, `service-context.xml` has `action-executer` bean |
| behaviours | content-types checks + `*Behaviour.java` implements `*Policy`, uses `PolicyComponent` + `JavaBehaviour`, no `LANGUAGE_LUCENE` |
| web-scripts | content-types checks + all `*.desc.xml` have `<authentication>`, `<format>`, `<transaction>`, `<cache>`, URL starts with `/api/`, `*.json.ftl` exists, `webscript-context.xml` exists |
| workflows | `*.bpmn` well-formed with `xmlns:activiti`, `isExecutable="true"`, no `org.flowable`, no `redeploy=true`; `*-workflow-model.xml` imports `bpm` namespace; `bootstrap-context.xml` uses `workflowDeployer`; `*Workflow.properties` exists |

## Dependencies

`bash`, `xmllint` (pre-installed on macOS), `grep` — no Docker, no Maven, no network.
