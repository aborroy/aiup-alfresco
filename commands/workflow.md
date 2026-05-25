---
description: "Generate Activiti BPMN 2.0 process definition, workflow task content model, Spring bootstrap registration, i18n message bundle, and optional Java task listener. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /workflow — Workflow Generator

> **In-Process SDK only** — Activiti workflows deploy inside the ACS JVM as part of the Platform JAR.
> Share UI form configuration is out of scope for ACS 26.1 (use ADF/ACA for task forms). The generated workflow is fully operable via the Alfresco Workflow REST API v1.

Generate Alfresco Activiti workflow artefacts from requirements.

## Input

Read `REQUIREMENTS.md` to identify workflow requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that `/workflow` only applies to the in-process Platform JAR project.

2. Read Section 7 (Behaviour Requirements) sub-section "Workflow requirements".
   - If no workflow requirements are listed in Section 7, stop and ask the user to run `/requirements` first (or provide a workflow description as `$ARGUMENTS`).

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `workflows`). Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from Section 2. **Never use the full `module.id` property value (e.g. `com.someco.workflows`) as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)

4. Derive from workflow requirements:
   - `{processName}` — camelCase process identifier (e.g. `publishWhitepaper`)
   - `{ProcessName}` — PascalCase process name (e.g. `PublishWhitepaper`)
   - `{prefix}wf` — workflow-specific namespace sub-prefix
   - User tasks, gateways, sequence flows, timer events, and service tasks as described

---

## Output Files

> **All four artefacts below are required and must be generated together in a single run:**
> the BPMN process definition, the workflow task content model XML, the Spring bootstrap
> registration, and the i18n message bundle. Never generate only a subset.
> The optional Java task listener (artefact 5) is generated only when the requirements
> describe custom Java logic in a task listener.

### 1. BPMN Process Definition
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/workflow/{processName}.bpmn`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:activiti="http://activiti.org/bpmn"
             xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
             xmlns:omgdc="http://www.omg.org/spec/DD/20100524/DC"
             xmlns:omgdi="http://www.omg.org/spec/DD/20100524/DI"
             typeLanguage="http://www.w3.org/2001/XMLSchema"
             expressionLanguage="http://www.w3.org/1999/XPath"
             targetNamespace="http://www.activiti.org/test">

  <process id="{processName}" name="{Process Human Name}" isExecutable="true">

    <!-- Start event — captures initiator inputs -->
    <startEvent id="startevent1" name="Start"
        activiti:formKey="{prefix}wf:submit{ProcessName}Task"/>

    <!-- Service task to initialize counters (when parallel approvals are needed) -->
    <serviceTask id="initCounters" name="Initialize"
        activiti:class="org.alfresco.repo.workflow.activiti.script.AlfrescoScriptDelegate">
      <extensionElements>
        <activiti:field name="runAs"><activiti:string>admin</activiti:string></activiti:field>
        <activiti:field name="script">
          <activiti:string><![CDATA[
            execution.setVariable('{prefix}wf_approveCount', 0);
          ]]></activiti:string>
        </activiti:field>
      </extensionElements>
    </serviceTask>

    <!-- Parallel gateway — split -->
    <parallelGateway id="parallelSplit" name="Split"/>

    <!-- User task — first reviewer -->
    <userTask id="reviewTask1" name="{First Reviewer Task}"
        activiti:candidateGroups="GROUP_{FirstGroup}"
        activiti:formKey="{prefix}wf:activiti{FirstTask}">
      <extensionElements>
        <activiti:taskListener event="complete"
            class="org.alfresco.repo.workflow.activiti.tasklistener.ScriptTaskListener">
          <activiti:field name="script">
            <activiti:string><![CDATA[
              if (task.getVariableLocal('{prefix}wf_{firstTask}Outcome') == 'Approve') {
                var count = execution.getVariable('{prefix}wf_approveCount');
                execution.setVariable('{prefix}wf_approveCount', count + 1);
              }
            ]]></activiti:string>
          </activiti:field>
        </activiti:taskListener>
      </extensionElements>
    </userTask>

    <!-- User task — second reviewer -->
    <userTask id="reviewTask2" name="{Second Reviewer Task}"
        activiti:candidateGroups="GROUP_{SecondGroup}"
        activiti:formKey="{prefix}wf:activiti{SecondTask}">
      <extensionElements>
        <activiti:taskListener event="complete"
            class="org.alfresco.repo.workflow.activiti.tasklistener.ScriptTaskListener">
          <activiti:field name="script">
            <activiti:string><![CDATA[
              if (task.getVariableLocal('{prefix}wf_{secondTask}Outcome') == 'Approve') {
                var count = execution.getVariable('{prefix}wf_approveCount');
                execution.setVariable('{prefix}wf_approveCount', count + 1);
              }
            ]]></activiti:string>
          </activiti:field>
        </activiti:taskListener>
      </extensionElements>
    </userTask>

    <!-- Timer boundary event example (attach to a user task when escalation is needed) -->
    <!--
    <boundaryEvent id="timerEscalation" cancelActivity="true" attachedToRef="reviewTask1">
      <timerEventDefinition>
        <timeDuration>PT5M</timeDuration>
      </timerEventDefinition>
    </boundaryEvent>
    -->

    <!-- Parallel gateway — join -->
    <parallelGateway id="parallelJoin" name="Join"/>

    <!-- Exclusive gateway — route based on approval count -->
    <exclusiveGateway id="approvalDecision" name="Approved?"/>

    <!-- Service task — approved path: invoke action on workflow package documents -->
    <serviceTask id="applyApprovedAction" name="Apply Approved Action"
        activiti:class="org.alfresco.repo.workflow.activiti.script.AlfrescoScriptDelegate">
      <extensionElements>
        <activiti:field name="runAs"><activiti:string>admin</activiti:string></activiti:field>
        <activiti:field name="script">
          <activiti:string><![CDATA[
            // Invoke an action on each document in the workflow package
            // var myAction = actions.create("{prefix}-{action-name}");
            // myAction.parameters["active"] = true;
            // for (var i = 0; i < bpm_package.children.length; i++) {
            //     myAction.execute(bpm_package.children[i]);
            // }
          ]]></activiti:string>
        </activiti:field>
      </extensionElements>
    </serviceTask>

    <!-- User task — rejected path: author revises and resubmits -->
    <userTask id="reviseTask" name="Revise and Resubmit"
        activiti:assignee="${initiator.properties.userName}"
        activiti:formKey="{prefix}wf:activiti{ProcessName}Revise"/>

    <!-- End events -->
    <endEvent id="endeventApproved" name="Approved"/>
    <endEvent id="endeventRejected" name="Rejected"/>

    <!-- Sequence flows -->
    <sequenceFlow id="flow1" sourceRef="startevent1" targetRef="initCounters"/>
    <sequenceFlow id="flow2" sourceRef="initCounters" targetRef="parallelSplit"/>
    <sequenceFlow id="flow3" sourceRef="parallelSplit" targetRef="reviewTask1"/>
    <sequenceFlow id="flow4" sourceRef="parallelSplit" targetRef="reviewTask2"/>
    <sequenceFlow id="flow5" sourceRef="reviewTask1" targetRef="parallelJoin"/>
    <sequenceFlow id="flow6" sourceRef="reviewTask2" targetRef="parallelJoin"/>
    <sequenceFlow id="flow7" sourceRef="parallelJoin" targetRef="approvalDecision"/>
    <sequenceFlow id="flow8" sourceRef="approvalDecision" targetRef="applyApprovedAction">
      <conditionExpression xsi:type="tFormalExpression">
        <![CDATA[${prefix}wf_approveCount == 2]]>
      </conditionExpression>
    </sequenceFlow>
    <sequenceFlow id="flow9" sourceRef="approvalDecision" targetRef="reviseTask">
      <conditionExpression xsi:type="tFormalExpression">
        <![CDATA[${prefix}wf_approveCount < 2]]>
      </conditionExpression>
    </sequenceFlow>
    <sequenceFlow id="flow10" sourceRef="applyApprovedAction" targetRef="endeventApproved"/>
    <sequenceFlow id="flow11" sourceRef="reviseTask" targetRef="endeventRejected"/>

  </process>

  <!-- BPMNDiagram coordinates are approximate — adjust layout with Camunda Modeler or Activiti Designer -->
  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane bpmnElement="{processName}" id="BPMNPlane_1">
      <bpmndi:BPMNShape bpmnElement="startevent1" id="BPMNShape_startevent1">
        <omgdc:Bounds height="35.0" width="35.0" x="30.0" y="162.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="initCounters" id="BPMNShape_initCounters">
        <omgdc:Bounds height="55.0" width="105.0" x="110.0" y="152.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="parallelSplit" id="BPMNShape_parallelSplit">
        <omgdc:Bounds height="40.0" width="40.0" x="260.0" y="159.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="reviewTask1" id="BPMNShape_reviewTask1">
        <omgdc:Bounds height="55.0" width="105.0" x="350.0" y="100.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="reviewTask2" id="BPMNShape_reviewTask2">
        <omgdc:Bounds height="55.0" width="105.0" x="350.0" y="220.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="parallelJoin" id="BPMNShape_parallelJoin">
        <omgdc:Bounds height="40.0" width="40.0" x="505.0" y="159.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="approvalDecision" id="BPMNShape_approvalDecision">
        <omgdc:Bounds height="40.0" width="40.0" x="595.0" y="159.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="applyApprovedAction" id="BPMNShape_applyApprovedAction">
        <omgdc:Bounds height="55.0" width="105.0" x="685.0" y="100.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="reviseTask" id="BPMNShape_reviseTask">
        <omgdc:Bounds height="55.0" width="105.0" x="685.0" y="220.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="endeventApproved" id="BPMNShape_endeventApproved">
        <omgdc:Bounds height="35.0" width="35.0" x="840.0" y="110.0"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape bpmnElement="endeventRejected" id="BPMNShape_endeventRejected">
        <omgdc:Bounds height="35.0" width="35.0" x="840.0" y="230.0"/>
      </bpmndi:BPMNShape>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>

</definitions>
```

**BPMN generation rules:**
- Always include `xmlns:activiti="http://activiti.org/bpmn"` on the root `<definitions>` element
- `<process id="...">` must have both `id` (camelCase) and `name` (human-readable) and `isExecutable="true"`
- User tasks must have either `activiti:assignee` or `activiti:candidateGroups` — never both, never neither
- Service tasks must specify `activiti:class="org.alfresco.repo.workflow.activiti.script.AlfrescoScriptDelegate"` for inline Alfresco scripts
- Use `ScriptTaskListener` on task complete events to promote local task variables to process variables
- Timer boundary events must have `cancelActivity="true"` or `cancelActivity="false"` explicitly set; duration must be ISO 8601 (e.g. `PT5M`, `PT1H`, `P1D`)
- Every `<exclusiveGateway>` with multiple outgoing flows must have `<conditionExpression>` on all but one (the default)
- Process variable names in all `<conditionExpression>` and `<activiti:string>` script blocks must use the **underscore form** (`{prefix}wf_propName`), not the colon form
- Do NOT reference `org.flowable.*` in any `class` attribute

---

### 2. Workflow Task Content Model
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/model/{processName}-workflow-model.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<model name="{prefix}wf:workflowModel"
       xmlns="http://www.alfresco.org/model/dictionary/1.0">

  <description>{Process Human Name} Workflow Model</description>
  <version>1.0</version>

  <imports>
    <import uri="http://www.alfresco.org/model/dictionary/1.0" prefix="d"/>
    <import uri="http://www.alfresco.org/model/content/1.0" prefix="cm"/>
    <import uri="http://www.alfresco.org/model/bpm/1.0" prefix="bpm"/>
  </imports>

  <namespaces>
    <namespace uri="http://www.{company}.com/model/workflow/1.0" prefix="{prefix}wf"/>
  </namespaces>

  <types>

    <!-- Start task — captures initiator inputs when the workflow is started -->
    <type name="{prefix}wf:submit{ProcessName}Task">
      <parent>bpm:startTask</parent>
      <properties>
        <!-- Add start-form properties here, e.g. reviewer group, due date -->
      </properties>
      <mandatory-aspects>
        <!-- Add aspects required at submission time -->
      </mandatory-aspects>
    </type>

    <!-- User task — approval step with Approve/Reject outcome -->
    <type name="{prefix}wf:activiti{FirstTask}">
      <parent>bpm:activitiOutcomeTask</parent>
      <properties>
        <property name="{prefix}wf:{firstTask}Outcome">
          <type>d:text</type>
          <default>Reject</default>
          <constraints>
            <constraint type="LIST">
              <parameter name="allowedValues">
                <list>
                  <value>Approve</value>
                  <value>Reject</value>
                </list>
              </parameter>
            </constraint>
          </constraints>
        </property>
      </properties>
      <overrides>
        <!-- Tell ACS which property holds the outcome decision -->
        <property name="bpm:packageItemActionGroup">
          <default>read_package_item_actions</default>
        </property>
        <property name="bpm:outcomePropertyName">
          <default>{http://www.{company}.com/model/workflow/1.0}{firstTask}Outcome</default>
        </property>
      </overrides>
    </type>

    <!-- Revise task — shown to the initiator when the workflow is rejected -->
    <type name="{prefix}wf:activiti{ProcessName}Revise">
      <parent>bpm:activitiOutcomeTask</parent>
      <overrides>
        <property name="bpm:packageItemActionGroup">
          <default>edit_package_item_actions</default>
        </property>
        <property name="bpm:outcomePropertyName">
          <default>{http://www.{company}.com/model/workflow/1.0}{processName}ReviseOutcome</default>
        </property>
      </overrides>
    </type>

  </types>

  <aspects>
    <!-- Optional workflow-specific aspects, e.g. reviewer email for external review -->
  </aspects>

</model>
```

**Workflow model rules:**
- Always import `bpm` namespace — workflow task types extend `bpm:startTask` or `bpm:activitiOutcomeTask`
- Use `bpm:startTask` as parent for the start task only
- Use `bpm:activitiOutcomeTask` for all user tasks that have outcome decisions
- Use `bpm:workflowTask` for notification-only tasks with no outcome
- Always set `bpm:outcomePropertyName` override to the fully qualified QName of the outcome property
- Never use `<mandatory enforced="true">` on workflow task properties (same integrity issue as regular types)
- Default outcome value should be the "safe" one (e.g. `Reject`)

---

### 3. Bootstrap Registration
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/bootstrap-context.xml`

**If the file already exists** (created by `/content-model`): read it and append the `workflowBootstrap` bean. Check whether a `{prefix}.workflowBootstrap` bean already exists — if so, add only the new `<props>` block inside the existing `workflowDefinitions` list and the new model/label entries; do not create a duplicate bean ID.

**If the file does not exist**: create it with only the `workflowBootstrap` bean (no `dictionaryBootstrap` — that is created by `/content-model`).

```xml
<!-- DEVELOPMENT NOTE: to redeploy after BPMN changes, use the Workflow Console:
     undeploy definition name {processName}
     Then restart ACS. Do NOT set redeploy=true — it creates duplicate definitions. -->
<bean id="{prefix}.workflowBootstrap" parent="workflowDeployer">
    <property name="workflowDefinitions">
        <list>
            <props>
                <prop key="engineId">activiti</prop>
                <prop key="location">alfresco/module/{module-id}/workflow/{processName}.bpmn</prop>
                <prop key="mimetype">text/xml</prop>
                <prop key="redeploy">false</prop>
            </props>
        </list>
    </property>
    <property name="models">
        <list>
            <value>alfresco/module/{module-id}/model/{processName}-workflow-model.xml</value>
        </list>
    </property>
    <property name="labels">
        <list>
            <value>alfresco.module.{module-id}.messages.{processName}Workflow</value>
        </list>
    </property>
</bean>
```

**Note:** `module-context.xml` already imports `bootstrap-context.xml` — no additional import line is needed.

---

### 4. i18n Message Bundle
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/messages/{processName}Workflow.properties`

```properties
# Process title and description — shown in the "Start Workflow" dialog
{processName}.workflow.title={Process Human Name}
{processName}.workflow.description={Brief description of the workflow purpose}

# Workflow model strings — type and property display names
# Key format: {prefix}wf_workflowModel.type.{prefix}wf_{TypeLocalName}.title
{prefix}wf_workflowModel.type.{prefix}wf_submit{ProcessName}Task.title=Start {Process Name} Workflow
{prefix}wf_workflowModel.type.{prefix}wf_activiti{FirstTask}.title={First Task Human Name}
{prefix}wf_workflowModel.type.{prefix}wf_activiti{ProcessName}Revise.title=Revise and Resubmit

# Property labels
# Key format: {prefix}wf_workflowModel.property.{prefix}wf_{propLocalName}.title
{prefix}wf_workflowModel.property.{prefix}wf_{firstTask}Outcome.title=Decision
```

---

### 5. Java Task Listener (optional)
`{platform-project-root}/src/main/java/{package}/workflow/{Name}TaskListener.java`

Generate only when requirements explicitly call for a Java-based task listener (e.g. sending email, calling an external service, complex conditional logic that exceeds inline script capability).

```java
package {package}.workflow;

import org.activiti.engine.delegate.DelegateTask;
import org.activiti.engine.delegate.TaskListener;
import org.activiti.engine.impl.cfg.ProcessEngineConfigurationImpl;
import org.activiti.engine.impl.context.Context;
import org.alfresco.repo.workflow.activiti.ActivitiConstants;
import org.alfresco.service.ServiceRegistry;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * {Description of what this task listener does}.
 *
 * NOTE: All activiti.engine.impl.* classes are available at runtime via
 * alfresco-repository (provided scope) — no additional Maven dependency is required.
 * Do NOT use @Autowired — Spring is not active in the Activiti task listener context.
 */
public class {Name}TaskListener implements TaskListener {

    private static final long serialVersionUID = 1L;
    private static final Log logger = LogFactory.getLog({Name}TaskListener.class);

    @Override
    public void notify(DelegateTask task) {
        logger.debug("{Name}TaskListener.notify() event=" + task.getEventName()
                + " taskId=" + task.getId());

        ServiceRegistry serviceRegistry = getServiceRegistry();
        // TODO: implement task listener logic using serviceRegistry
        // e.g. serviceRegistry.getMailService() for email
        // e.g. serviceRegistry.getNodeService() for node operations
    }

    private ServiceRegistry getServiceRegistry() {
        ProcessEngineConfigurationImpl config = Context.getProcessEngineConfiguration();
        if (config == null) {
            throw new IllegalStateException(
                "No active ProcessEngineConfiguration — is this code running inside an Activiti task callback?");
        }
        ServiceRegistry registry = (ServiceRegistry) config.getBeans()
                .get(ActivitiConstants.SERVICE_REGISTRY_BEAN_KEY);
        if (registry == null) {
            throw new IllegalStateException(
                "ServiceRegistry not present in ProcessEngineConfiguration beans");
        }
        return registry;
    }
}
```

Register in the BPMN:
```xml
<activiti:taskListener event="create" class="{package}.workflow.{Name}TaskListener"/>
```

---

## Conventions

| Item | Rule |
|------|------|
| `{platform-project-root}` | `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode |
| `{prefix}wf` | Workflow-specific namespace sub-prefix; derived from the content model prefix |
| Process variable names | Always underscore form (`{prefix}wf_{propName}`) in BPMN — never colon |
| Task parent types | `bpm:startTask` for start; `bpm:activitiOutcomeTask` for approval/decision; `bpm:workflowTask` for notification-only |
| `redeploy` flag | Always `false` — use Workflow Console to undeploy before changing a deployed definition |
| Share forms | Not generated — this workflow is testable and operable via the Workflow REST API v1 |
| `module-context.xml` | No import change needed; `bootstrap-context.xml` is already imported by `/scaffold` |

## Workflow Position in Command Chain

```
/requirements → /scaffold → /content-model → /workflow → /behaviours → /web-scripts → /actions → /events → /docker-compose → /test
```

Run `/workflow` after `/content-model` (so the `{prefix}` namespace is established and `bootstrap-context.xml` may already exist) and before `/behaviours`/`/actions` (which may reference workflow actions or aspects).

## Validation

After generating files, invoke the `workflow-bpmn-validator` skill to validate the BPMN and workflow model for structural correctness and forbidden patterns.
