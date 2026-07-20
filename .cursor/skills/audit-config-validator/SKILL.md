---
name: audit-config-validator
description: Validates custom Alfresco audit application XML for well-formedness, correct audit model namespace, application key matching the enable property, and every RecordValue dataExtractor/dataGenerator referencing a declared and registered bean. Trigger automatically after generating or editing a *-audit.xml or an audit *DataExtractor.java / *DataGenerator.java file.
---


# Audit Config Validator

Validate the given custom Alfresco audit application against these rules.

## XML Structure Validation
- The audit XML must be well-formed and its root `<Audit>` element must declare the audit model
  namespace `http://www.alfresco.org/repo/audit/model/3.2`.
- There must be exactly one `<Application>` with both `name` and `key` attributes.

## Application Key / Enable Consistency
- The `<Application key="{app-key}">` value must be lowercase and prefix-scoped.
- **FLAG as ERROR** if no `audit.{app-key}.enabled` property is present in a companion
  `.properties` file matching the `key` exactly.
  - **Why it breaks**: the application is defined but never enabled, so nothing is recorded.
- **WARN** if `audit.enabled=true` (the master switch) is not present anywhere in the project.

## Extractor / Generator Wiring
- Every `<RecordValue dataExtractor="X">` must reference a `<DataExtractor name="X" ...>`
  declared in `<DataExtractors>`.
- Every `<RecordValue dataGenerator="Y">` must reference a `<DataGenerator name="Y" ...>`
  declared in `<DataGenerators>`.
- For each custom (non-built-in) `<DataExtractor registeredName="...">`, there must be a Spring
  bean whose `registeredName` property matches, with `parent="auditModelExtractorBase"`.
  - **FLAG as ERROR** a `registeredName` with no matching bean (the application fails to register
    or records nothing).

## Java Extractor Validation
- If a `*DataExtractor.java` exists, it must `extends AbstractDataExtractor` and implement
  `isSupported` and `extractData`.
- If a `*DataGenerator.java` exists, it must `extends AbstractDataGenerator`.

## Registration Validation
- The audit model must be registered via an `AuditModelRegistrationBean`
  (`init-method="registerModel"`) whose `auditModelUrl` points at the audit XML on the classpath.
- The registering context must be imported from `module-context.xml`.
- **WARN** if `<PathMappings>` is absent while `dataSource` paths reference a producer path that
  is not mapped into the application namespace.

## Output
Report all violations with file path, line number, rule violated, and suggested fix. If no
violations found, confirm the audit application is valid.
