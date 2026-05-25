# Requirements: Rule Conditions

## 1. Business Purpose
Provide a custom rule condition that evaluates whether a document has the `sc:webable`
aspect applied, so that folder rules can trigger actions (such as publishing) only on
web-enabled documents. A second condition checks whether `sc:isActive` is set to a
specific boolean value.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: rule-conditions
- **Platform module**: rule-conditions
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As a rule author, I can add a condition "Has Webable Aspect" to a folder rule so that
  actions only fire on documents that have `sc:webable` applied.
- As a rule author, I can add a condition "Is Active Document" with a boolean parameter to
  match documents where `sc:isActive` equals the specified value.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Aspects
- `sc:webable` — aspect marking a document as web-publishable
- `sc:rateable` — aspect for rating support (optional, not checked in this rule)

### Types
- `sc:doc` extends `cm:content`
  - `sc:isActive` (d:boolean, optional)

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Rule condition requirements
- **Condition 1 — `HasWebableAspect`**
  - Condition ID: `sc-has-webable-aspect`
  - No parameters
  - Returns `true` if the node has the `sc:webable` aspect

- **Condition 2 — `IsActiveDocument`**
  - Condition ID: `sc-is-active-document`
  - Parameter: `active` (d:boolean, mandatory=false, default treat null as true)
  - Returns `true` if `sc:isActive` on the node equals the `active` parameter value

Both conditions must:
- Extend `ActionConditionEvaluatorAbstractBase`
- Override `evaluateImpl(ActionCondition, NodeRef)`
- Use `parent="action-condition-evaluator"` in Spring XML
- Register in `service-context.xml`
- Not use `@Autowired`, `@Transactional`, or `@PostConstruct`

## 8. Deployment Requirements
- Platform JAR with condition beans registered in `service-context.xml`.
- `service-context.xml` imported from `module-context.xml`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | HasWebableAspectCondition.java, service-context.xml | HasWebableAspectConditionTest.java |
| US-02 | IsActiveDocumentCondition.java, service-context.xml | IsActiveDocumentConditionTest.java |
