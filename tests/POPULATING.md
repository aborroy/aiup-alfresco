# Populating generated/ for validate-tutorials

The harness ships with a fully automated script that generates all scenario artefacts
using `claude -p` (non-interactive mode) and then validates them.

---

## Fully automated: generate + check in one command

```bash
cd aiup-alfresco/tests/validate-tutorials

# Generate all 6 scenarios, then check them:
./generate-all.sh && ./run-all.sh
```

No interactive input needed. `generate-all.sh`:

1. For each scenario, cleans `generated/<scenario>/`, copies the matching
   `scenarios/<scenario>/REQUIREMENTS.md` into it.
2. Renders each required aiup slash command via `scripts/aiup-command.sh render`.
3. Pipes the rendered prompt into `claude -p --dangerously-skip-permissions`,
   which writes files directly into the generated directory.
4. Repeats for each command in sequence (scaffold → content-model → domain command).

`run-all.sh` then checks all 6 generated directories and prints a summary.

Expected final output:

```
Scenario                       Result
----------------------------------------------
maven-sdk-baseline             PASS
content-types                  PASS
actions                        PASS
behaviours                     PASS
web-scripts                    PASS
workflows                      PASS
----------------------------------------------
TOTAL                          PASS:6  FAIL:0  SKIP:0
```

---

## Generate a single scenario

```bash
./generate-all.sh content-types
./run-scenario.sh content-types
```

---

## Requirements

- `claude` CLI in PATH (no `--plugin-dir` needed — `generate-all.sh` uses
  `scripts/aiup-command.sh render` which reads command specs directly from the
  repository, not from Claude Code's plugin system)

---

## What each scenario generates

| Scenario | Commands run | Key files checked |
|----------|-------------|-------------------|
| maven-sdk-baseline | `/scaffold` | `pom.xml` (sdk-aggregator), `module.properties`, `module-context.xml` |
| content-types | `/scaffold` `/content-model` | + `content-model.xml`, `*Model.java` (QName), `bootstrap-context.xml` (dictionaryModelBootstrap) |
| actions | `/scaffold` `/content-model` `/actions` | + `*ActionExecuter.java` (extends ActionExecuterAbstractBase), `service-context.xml` (action-executer) |
| behaviours | `/scaffold` `/content-model` `/behaviours` | + `*Behaviour.java` (Policy, PolicyComponent, JavaBehaviour, no LANGUAGE_LUCENE), `service-context.xml` |
| web-scripts | `/scaffold` `/content-model` `/web-scripts` | + `*.desc.xml` (auth, format, transaction, cache, /api/ URL), `*.json.ftl`, `webscript-context.xml` |
| workflows | `/scaffold` `/content-model` `/workflow` | + `*.bpmn` (activiti ns, isExecutable, no flowable/redeploy), `*-workflow-model.xml` (bpm import), `bootstrap-context.xml` (workflowDeployer), `*Workflow.properties` |

---

## Troubleshooting

**A scenario generates 0 files or Claude asks for input**
The `claude -p` invocation didn't find `REQUIREMENTS.md`. The script appends an explicit
path context to every prompt, but if Claude's model changes its behaviour, run the failing
scenario individually and check its `.prompt-*.txt` log:

```bash
./generate-all.sh content-types
# Inspect what was sent to claude:
cat generated/content-types/.prompt-scaffold.txt | head -20
```

**A scenario FAIL after generation**
The checker output shows exactly which file and pattern failed. Common cases:

- `FAIL: *.bpmn process definition file exists` — the `/workflow` command generated the
  model but not the BPMN. Re-run `./generate-all.sh workflows`; non-determinism in LLM
  output means a second run often produces the missing file.
- `FAIL: all descriptors use /api/ URL prefix` — `/web-scripts` generated `/someco/` URLs
  instead of `/api/sc/`. This is a gap in the command spec to fix in `commands/web-scripts.md`.
- `FAIL: bootstrap-context.xml uses workflowDeployer` — `/workflow` registered BPMN via
  `dictionaryModelBootstrap` (forbidden pattern). Re-run or fix `bootstrap-context.xml` manually.
- `FAIL: *Model.java uses two-arg QName.createQName()` — `/content-model` used the
  one-arg form. This is a gap in `commands/content-model.md` to fix.
