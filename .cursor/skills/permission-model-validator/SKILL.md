---
name: permission-model-validator
description: Validates custom Alfresco permission model XML for well-formedness, no collision with built-in permission group names, correct permissionSet binding, and that any dynamic authority is registered and implements DynamicAuthority. Trigger automatically after generating or editing a *permissionDefinitions.xml or a *DynamicAuthority.java file.
---


# Permission Model Validator

Validate the given custom Alfresco permission model and dynamic authorities against these rules.

## XML Structure Validation
- The file must be well-formed XML with root element `<permissions>`.
- Each `<permissionSet>` must declare a `type` attribute bound to a **custom** type or aspect
  (`{prefix}:...`), not a redefinition of a core type that removes built-in groups.
- Each `<permissionGroup>` and `<permission>` must declare a `name`.

## Built-in Name Collision
- **FLAG as ERROR** any `<permissionGroup name="...">` or `<permission name="...">` whose name
  collides with a built-in Alfresco permission group/permission: `Read`, `Write`, `Delete`,
  `AddChildren`, `ReadProperties`, `ReadChildren`, `WriteProperties`, `Consumer`, `Contributor`,
  `Editor`, `Collaborator`, `Coordinator`, `SiteManager`, `SiteCollaborator`, `SiteContributor`,
  `SiteConsumer`, `FullControl`, `All`.
  - **Why it breaks**: redefining a core group name corrupts the global permission model and can
    silently alter access across the whole repository.
  - **Fix**: use a project-scoped PascalCase name; compose on top of a core group with
    `<includePermissionGroup permissionGroup="Read" type="cm:cmobject"/>`.

## Registration Validation
- The model must be registered as an **extension** model, not a replacement: look for a Spring
  bean with `parent="permissionModelBootstrap"` and a `model` property pointing at the
  `permissionDefinitions.xml` under `alfresco/extension/`.
  - **WARN** if no such registration bean is found in a companion `*-context.xml`.
- The registering context must be imported from `module-context.xml`.

## Dynamic Authority Validation
- If a `*DynamicAuthority.java` exists:
  - It must `implements DynamicAuthority` (from `org.alfresco.repo.security.permissions`).
  - It must implement `hasAuthority`, `getAuthority`, and `requiredFor`.
  - **FLAG as ERROR** `runAsSystem` inside `hasAuthority` (privilege escalation + per-node perf
    hazard).
  - **WARN** if `hasAuthority` does not guard with `nodeService.exists()`.
  - The bean must be registered (id `{prefix}.{name}DynamicAuthority`) and added to the global
    `dynamicAuthorities` list.
- **WARN** if a permission/group omits `requiresType` where it logically applies only to the
  bound type.

## Output
Report all violations with file path, line number, rule violated, and suggested fix. If no
violations found, confirm the permission model is valid.
