---
name: content-model-validator
description: Validates Alfresco content model XML files for correct namespace URI format, mandatory type/aspect declarations, valid property data types, and absence of reserved prefixes (sys:, cm:, app:). Trigger automatically when generating or editing *-model*.xml or *-context.xml files.
---


# Content Model Validator

Validate the given Alfresco content model XML against these rules:

## Namespace Validation
- Namespace URI must follow the pattern `http://www.{company}.com/model/{prefix}/{version}`
- Namespace prefix must not collide with reserved Alfresco prefixes: `sys`, `cm`, `app`, `usr`, `act`, `wcm`, `wca`, `lnk`, `fm`, `dl`, `ia`, `smf`, `imap`, `emailserver`, `bpm`, `wcmwf`, `trx`, `stcp`
- Prefix must be lowercase alphanumeric, 2-6 characters

## Structure Validation
- Root element must be `<model>` with `name` attribute in format `{prefix}:modelName`
- Must contain `<namespaces>` with at least one `<namespace>` declaration
- If types are declared, they must be inside `<types>` element
- If aspects are declared, they must be inside `<aspects>` element

## Type and Aspect Validation
- Every `<type>` must have a `name` attribute in format `{prefix}:typeName`
- Every `<type>` should declare a `<parent>` (default: `cm:content` or `cm:folder`)
- Property names must use the model prefix: `{prefix}:propertyName`
- Property `<type>` must be a valid Alfresco data type: `d:text`, `d:mltext`, `d:int`, `d:long`, `d:float`, `d:double`, `d:date`, `d:datetime`, `d:boolean`, `d:noderef`, `d:content`, `d:any`, `d:category`, `d:qname`, `d:locale`, `d:period`

## Mandatory Property Enforcement
- **FLAG as ERROR** any property that uses `<mandatory enforced="true">true</mandatory>`.
  - **Why it breaks**: `enforced="true"` makes ACS fire the `IntegrityChecker` immediately
    inside `OnAddAspectPolicy`, which runs *before* `NodeServiceImpl.addAspect()` has written
    the properties map to the database.  The result is a spurious `IntegrityException:
    Mandatory property not set` even when the caller passes a fully-populated properties map.
  - **Fix**: Use `<mandatory>true</mandatory>` (no `enforced` attribute).  The integrity check
    is then deferred to `beforeCommit`, by which time `addAspect()` has written both the aspect
    and its properties.
  - **Exception**: `enforced="true"` is safe only on properties belonging to **types** (not
    aspects), where the property must be supplied at node creation time via the REST API and
    is never set programmatically after the fact.

## Constraint Validation
- Each `<constraint>` must declare a `name` (`{prefix}:{camelCaseConstraintName}`) and a `type`.
- For built-in constraint types, verify the required parameters are present:
  - `LIST` — must have an `allowedValues` `<list>` parameter with at least one `<value>`.
  - `REGEX` — must have an `expression` parameter; a `requiresMatch` parameter is recommended.
  - `LENGTH` — must have `minLength` and/or `maxLength` parameters.
  - `MINMAX` — must have `minValue` and/or `maxValue` parameters.
- For a **custom** constraint, `type` is a fully-qualified class name; it should resolve to a
  class extending `org.alfresco.repo.dictionary.constraint.AbstractConstraint`. Flag a `type`
  that is neither a built-in keyword (`LIST`, `REGEX`, `LENGTH`, `MINMAX`) nor a resolvable class.
- A property `<constraints><constraint ref="{prefix}:..."/></constraints>` reference must point
  at a constraint defined in the same model (or an imported one).

## Association Validation
- `<child-association>` and `<association>` must declare a `name` (`{prefix}:...`) and a
  `<source>`/`<target>` with a `<class>`; cardinality is expressed via `<mandatory>` and `<many>`.
- Prefer `<child-association>` for composition (cascade delete) and `<association>` for peer
  references — flag a child association used where a non-owning reference is intended.

## Spring Context Validation
- If a companion `*-context.xml` exists, verify it registers the model via `<bean class="org.alfresco.repo.dictionary.DictionaryBootstrap">` or equivalent
- The `models` property must reference the correct model XML path

## Output
Report all violations with file path, line number, rule violated, and suggested fix. If no violations found, confirm the model is valid.
