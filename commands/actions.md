---
description: "Scaffold Alfresco ActionExecuter classes with Spring bean registration. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /actions — Action Executor Generator

> **In-Process SDK only** — deploys inside the ACS JVM as a Platform JAR.

Generate Alfresco action classes.

## Input
Read `REQUIREMENTS.md` to identify action requirements and resolve the Platform JAR
project's `Root path` from Section 2 (Project Architecture).

- If Section 2 contains no `Platform JAR` project, stop and explain that `/actions`
  only applies to the in-process repository addon project.

## Output Files

### 1. Action Class
`{platform-project-root}/src/main/java/{package}/action/{Name}ActionExecuter.java`
- Extend `ActionExecuterAbstractBase`
- Implement `executeImpl()` method
- Define parameters via `addParameterDefinitions()`

### 2. Spring Bean Registration
Add to `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/service-context.xml`:
```xml
<bean id="{prefix}.{actionName}" class="{package}.action.{Name}ActionExecuter" parent="action-executer">
    <property name="nodeService" ref="NodeService"/>
    <!-- additional service references -->
</bean>
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID (e.g. `actions`), not the full `module.id` property value (e.g. `com.someco.actions`). Derive it as `{platform-artifactId}` from Section 2 of `REQUIREMENTS.md` or from `<artifactId>` in the platform `pom.xml`. **Never use `{groupId}.{artifactId}` as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Action name format: `{prefix}-{action-name}`
- Use parent `action-executer` bean
- Define compensation action if the operation is reversible
- Never generate action executers inside the Event Handler project
