---
name: workflow-bpmn-validator
description: Validates Alfresco Activiti BPMN 2.0 process definition files and companion workflow model XML for structural correctness: required namespaces, task assignees, variable naming conventions, process variable promotion pattern, formKey alignment, and forbidden Activiti 6/Flowable patterns. Trigger automatically when generating or editing *.bpmn files or *-workflow-model.xml files.
---


# Workflow BPMN Validator

Validate the given Alfresco Activiti BPMN process definition (and companion workflow model, if present) against these rules.

## BPMN Namespace Validation

- Root element must be `<definitions>` with BPMN 2.0 namespace:
  `xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"`
- **REQUIRED**: `xmlns:activiti="http://activiti.org/bpmn"` — must be present; Alfresco Activiti extensions use this namespace
- **ERROR if present**: Any `org.flowable.*` class reference in `class` attributes of `<activiti:taskListener>`, `<activiti:executionListener>`, or `<serviceTask activiti:class="...">`. ACS 26.1 uses Activiti 5.22.x; the Flowable API is not on the classpath.

## Process Structure Validation

- `<process>` element must have:
  - `id` attribute (camelCase identifier)
  - `name` attribute (human-readable)
  - `isExecutable="true"`
- **WARNING** if any `<startEvent>` is missing `activiti:formKey` in a non-trivial process (more than one user task)
- Every `<userTask>` must have either `activiti:assignee` or `activiti:candidateGroups`:
  - **WARNING** if a user task has neither — it will never be claimable
  - **WARNING** if a user task that represents an approval step is missing `activiti:formKey`
- Every `<exclusiveGateway>` with multiple outgoing sequence flows must have `<conditionExpression>` on all but one outgoing flow:
  - **ERROR** if an outgoing flow from an exclusive gateway has no condition and is not marked as `default`
- Every `<serviceTask>` must have either `activiti:class` or `activiti:expression` or `activiti:delegateExpression`:
  - **WARNING** for service tasks with none of these attributes (becomes a no-op)

## Variable Naming Validation

- Scan all `<activiti:string>` blocks inside `<activiti:field name="script">` elements and inside `<conditionExpression>` elements
- **ERROR** if any call to `execution.setVariable(...)` or `task.getVariableLocal(...)` uses a variable name containing a colon (e.g. `acme:outcome`). The correct form uses underscore (`acme_outcome`). Alfresco maps content model properties `{prefix}wf:{propName}` → process variable `{prefix}wf_{propName}` (colon → underscore).
- **ERROR** if any `<conditionExpression>` references a variable with a colon in the name (e.g. `${acme:count == 2}`). Use `${acme_count == 2}`.

## Task Listener Validation

- Any `<activiti:taskListener>` or `<activiti:executionListener>` using a `class` attribute:
  - **ERROR** if the class is from `org.flowable.*`
  - Allowed built-in classes: `org.alfresco.repo.workflow.activiti.tasklistener.ScriptTaskListener`, `org.alfresco.repo.workflow.activiti.listener.ScriptExecutionListener`
  - **INFO** if the class is custom (not from `org.alfresco.*`) — confirm it implements `org.activiti.engine.delegate.TaskListener`

## Timer Event Validation

- Every `<boundaryEvent>` containing a `<timerEventDefinition>` must have:
  - `cancelActivity` attribute explicitly set to `"true"` or `"false"` — **WARNING** if missing
  - Timer duration in ISO 8601 format inside `<timeDuration>`: `PT{N}S`, `PT{N}M`, `PT{N}H`, `P{N}D`, or combinations — **ERROR** if the format does not match ISO 8601

## Workflow Model Alignment

If a companion `*-workflow-model.xml` exists in the same module's `model/` directory:

- Every `activiti:formKey` value in the BPMN must correspond to a `<type name="...">` declared in the workflow model:
  - **ERROR** if a formKey references a type not present in the workflow model
- The workflow model must import the `bpm` namespace:
  `<import uri="http://www.alfresco.org/model/bpm/1.0" prefix="bpm"/>`
  - **ERROR** if this import is missing
- Every workflow task type must extend `bpm:startTask`, `bpm:activitiOutcomeTask`, or `bpm:workflowTask`:
  - **WARNING** if a type in the workflow model has no recognized `bpm:` parent
- **ERROR** if any property in the workflow model uses `<mandatory enforced="true">` — the integrity checker fires before `addAspect()` writes properties, causing a spurious `IntegrityException`

## Bootstrap Registration Check

If a `bootstrap-context.xml` exists in the module's `context/` directory:
- **WARNING** if it contains a `<bean>` with `parent="dictionaryModelBootstrap"` that lists a `.bpmn` file in its `models` property — BPMN files must be registered via `parent="workflowDeployer"`, not `dictionaryModelBootstrap`
- **WARNING** if the `workflowDeployer` bean has `<prop key="redeploy">true</prop>` — this causes duplicate process definitions on every restart

## Output

Report all violations with:
- File path and element ID (BPMN) or type name (workflow model)
- Rule violated
- Suggested fix

If no violations are found, confirm: "BPMN and workflow model are valid for ACS 26.1 / Activiti 5.x."
