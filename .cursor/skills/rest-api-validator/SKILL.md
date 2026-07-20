---
name: rest-api-validator
description: Validates Alfresco v1 Public REST API resources for correct annotations (@EntityResource / @RelationshipResource), required @WebApiDescription on every action method, a single @UniqueId on the model POJO, paged collection returns, and absence of classic Web Script anti-patterns. Trigger automatically after generating or editing files under a rest/ package or any class annotated @EntityResource / @RelationshipResource.
---


# REST API Validator

Validate the given Alfresco v1 Public REST API resources against these rules. This is the
modern annotation-based framework (`org.alfresco.rest.framework`), not classic Web Scripts.

## Annotation Validation
- Every entity resource class must be annotated `@EntityResource(name = "...", title = "...")`.
- Every relationship resource class must be annotated
  `@RelationshipResource(name = "...", entityResource = X.class, title = "...")`, and its
  `entityResource` must reference an existing `@EntityResource`-annotated class in the project.
- The `name` on both annotations must be **plural, kebab-case** (e.g. `vendor-contracts`,
  `payments`) and contain no verbs.

## Action Method Validation
- The resource class must implement at least one interface from
  `org.alfresco.rest.framework.resource.actions.interfaces` —
  `EntityResourceAction.Read` / `ReadById` / `Create` / `Update` / `Delete`, or
  `RelationshipResourceAction.Read` / `Create` / `Update` / `Delete`.
- **FLAG as ERROR** any public action method (`readAll`, `readById`, `create`, `update`,
  `delete`) that is **missing `@WebApiDescription`**.
  - **Why it breaks**: the framework only maps annotated methods. An unannotated action method
    is silently unreachable and the operation returns `405 Method Not Allowed`.
  - **Fix**: add `@WebApiDescription(title = "…")` to every action method.
- A `readAll` method must return `CollectionWithPagingInfo<T>` — **FLAG as ERROR** a raw
  `List<T>` / `Collection<T>` return (bypasses the paging envelope).

## Model POJO Validation
- The returned/consumed model POJO must have **exactly one** getter annotated `@UniqueId`.
  - **FLAG as ERROR** zero `@UniqueId` getters (framework cannot build `readById` / serialise id).
  - **FLAG as ERROR** more than one `@UniqueId` getter (ambiguous identifier).
- The POJO should be a plain JavaBean: public no-arg constructor, getters/setters, no Alfresco
  service fields.

## Forbidden Patterns
- **FLAG as ERROR** a resource class that `extends DeclarativeWebScript` — that is the classic
  framework and will not be discovered by `ResourceLookupDictionary`.
- **FLAG as ERROR** `@Autowired` — use setter injection wired in `webscript-context.xml`.
- **WARN** if `@PostConstruct` or `@Transactional` appears on a resource class.

## Spring Registration Validation
- Each resource should be registered as a `<bean>` in `webscript-context.xml`
  (bean id `{prefix}.{entity}EntityResource` / `{prefix}.{entity}{Relationship}RelationshipResource`),
  and `webscript-context.xml` should be imported from `module-context.xml`.
- A resource bean needs **no parent bean** — flag a `parent="..."` on a resource bean as
  likely incorrect.

## Output
Report all violations with file path, line number, rule violated, and suggested fix. If no
violations found, confirm the REST API resources are valid.
