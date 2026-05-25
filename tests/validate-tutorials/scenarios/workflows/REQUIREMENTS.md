# Requirements: Workflows

## 1. Business Purpose
Implement a "Publish Whitepaper" approval workflow that routes a document through parallel
Operations and Marketing reviews, with a third-party review step that escalates via a
timer boundary event. Mirrors the publishWhitepaper workflow from the alfresco-developer-series
workflow tutorial.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: workflows
- **Platform module**: workflows-platform
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an initiator, I can start a Publish Whitepaper workflow on a document.
- As an Operations reviewer, I can approve or reject the document.
- As a Marketing reviewer, I can approve or reject the document.
- As a third-party reviewer, I can approve the document; if I do not respond within 5 minutes,
  the process escalates.
- As a content manager, after both reviews pass, the document is automatically published.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/workflow/1.0`
- **Prefix**: `scwf`

### Workflow task types (workflow model)
- `scwf:submitReviewTask` extends `bpm:startTask`
- `scwf:activitiOperationsReview` extends `bpm:activitiOutcomeTask`
  - `scwf:approveRejectOutcome` (d:text, LIST: Approve | Reject)
- `scwf:activitiMarketingReview` extends `bpm:activitiOutcomeTask`
  - `scwf:approveRejectOutcome` (d:text, LIST: Approve | Reject)
- `scwf:activitiThirdPartyReview` extends `bpm:activitiOutcomeTask`
  - `scwf:approveRejectOutcome` (d:text, LIST: Approve | Reject)
- `scwf:activitiPublish` extends `bpm:workflowTask`
- `scwf:activitiReject` extends `bpm:workflowTask`

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Workflow requirements
- Process name: `publishWhitepaper`
- Engine: activiti (Activiti 5.22.x embedded in ACS 26.1)
- Start event has formKey `scwf:submitReviewTask`
- Parallel gateway fans out to Operations review task (candidateGroup: GROUP_Operations)
  and Marketing review task (candidateGroup: GROUP_Marketing)
- Parallel gateway joins after both reviews
- After join: exclusive gateway routes to Third-Party review task (assignee: initiator)
  if both approved, otherwise to Reject end
- Third-Party review task has timer boundary event (PT5M) escalating to an Expired task
- Third-party task uses a custom Java task listener `ExternalReviewNotification`
  on the "create" event
- After Third-Party approval: automatic Publish script task sets sc:isActive=true;
  then end event
- All process variables use underscore form: `scwf_approveCount`, `scwf_approveRejectOutcome`
- No `org.flowable.*` references; no `redeploy=true`

## 8. Deployment Requirements
- Platform JAR with workflow registered via workflowDeployer bean (not dictionaryModelBootstrap).
- Separate dictionaryBootstrap bean for the workflow task content model (if shared with main model,
  ensure two distinct beans coexist in bootstrap-context.xml).

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | publishWhitepaper.bpmn, bootstrap-context.xml | |
| US-02 | publishWhitepaper.bpmn | |
| US-03 | publishWhitepaper.bpmn | |
| US-04 | publishWhitepaper.bpmn, ExternalReviewNotification.java | |
| US-05 | publishWhitepaper.bpmn | |
