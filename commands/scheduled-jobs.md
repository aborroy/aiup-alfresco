---
description: "Generate a cluster-safe Quartz scheduled job with configurable cron expression, separate executer bean, Spring scheduler registration, and unit test. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /scheduled-jobs — Scheduled Job Generator

> **In-Process SDK only** — Quartz jobs deploy inside the ACS JVM as part of the Platform JAR.
> Never use Spring's `@Scheduled` in a Platform JAR — it is not integrated with Alfresco's
> Quartz scheduler or the `JobLockService` cluster-safety mechanism.

Generate a cluster-safe Alfresco scheduled job from requirements.

## Input

Read `REQUIREMENTS.md` to identify scheduled job requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that `/scheduled-jobs`
     only applies to the in-process Platform JAR project.

2. Read Section 7 (Behaviour Requirements) sub-section "Scheduled job requirements".
   - If no scheduled job requirements are present in Section 7, stop and ask the user to run
     `/requirements` first (or provide a description as `$ARGUMENTS`).

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `scheduled-jobs`).
     Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from
     Section 2. **Never use the full `module.id` property value as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)

4. Derive from scheduled job requirements:
   - `{jobName}` — camelCase job identifier (e.g. `contentArchiver`)
   - `{JobName}` — PascalCase job name (e.g. `ContentArchiver`)
   - `{cronDefault}` — default Quartz 6-field cron expression (e.g. `0 0 0 * * ?` for midnight daily)
   - Services the executer needs (e.g. `NodeService`, `SearchService`, `ContentService`)

---

## Output Files

> **All four artefacts below are required and must be generated together in a single run:**
> the Job class, the Executer class, the scheduler context XML, and the unit test.

### 1. Job Class
`{platform-project-root}/src/main/java/{package}/job/{JobName}Job.java`

```java
package {package}.job;

import org.alfresco.schedule.AbstractScheduledLockedJob;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class {JobName}Job extends AbstractScheduledLockedJob {

    private static final Logger LOG = LoggerFactory.getLogger({JobName}Job.class);

    private {JobName}JobExecuter executer;

    @Override
    public void executeJob(JobExecutionContext context) throws JobExecutionException {
        LOG.debug("Starting {JobName}Job");
        executer.execute();
    }

    public void setExecuter({JobName}JobExecuter executer) {
        this.executer = executer;
    }
}
```

- Always extend `AbstractScheduledLockedJob` — never implement `org.quartz.Job` directly.
- The Job class must be stateless: no Alfresco service fields. All logic belongs in the executer.
- `executeJob()` is the entry point called by Quartz after the lock is acquired.

### 2. Executer Class
`{platform-project-root}/src/main/java/{package}/job/{JobName}JobExecuter.java`

```java
package {package}.job;

import org.alfresco.repo.transaction.RetryingTransactionHelper;
import org.alfresco.service.ServiceRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class {JobName}JobExecuter {

    private static final Logger LOG = LoggerFactory.getLogger({JobName}JobExecuter.class);

    private RetryingTransactionHelper retryingTransactionHelper;
    private ServiceRegistry serviceRegistry;

    public void execute() {
        retryingTransactionHelper.doInTransaction(() -> {
            LOG.info("{JobName}Job executing");
            // business logic here — use serviceRegistry.getNodeService(), etc.
            return null;
        }, false, true);
    }

    public void setRetryingTransactionHelper(RetryingTransactionHelper h) {
        this.retryingTransactionHelper = h;
    }

    public void setServiceRegistry(ServiceRegistry serviceRegistry) {
        this.serviceRegistry = serviceRegistry;
    }
}
```

- All business logic goes here; the executer is a plain Spring bean testable without Quartz.
- Wrap every repository operation in `retryingTransactionHelper.doInTransaction()`.
- Never annotate with `@Transactional` — Alfresco manages transactions via `RetryingTransactionHelper`.
- Inject only the specific Alfresco services needed; use setter injection for XML wiring.

### 3. Scheduler Context XML
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/scheduler-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- Executer: holds business logic and injected Alfresco services -->
    <bean id="{prefix}.{jobName}Executer"
          class="{package}.job.{JobName}JobExecuter">
        <property name="retryingTransactionHelper" ref="retryingTransactionHelper"/>
        <property name="serviceRegistry"           ref="ServiceRegistry"/>
    </bean>

    <!-- Job detail: wires the Quartz Job class to the executer -->
    <bean id="{prefix}.{jobName}JobDetail"
          class="org.springframework.scheduling.quartz.JobDetailFactoryBean">
        <property name="jobClass" value="{package}.job.{JobName}Job"/>
        <property name="jobDataAsMap">
            <map>
                <entry key="executer" value-ref="{prefix}.{jobName}Executer"/>
            </map>
        </property>
    </bean>

    <!-- Trigger: cron expression and enabled flag are property-configurable -->
    <bean id="{prefix}.{jobName}Trigger"
          class="org.alfresco.util.CronTriggerBean">
        <property name="jobDetail"      ref="{prefix}.{jobName}JobDetail"/>
        <property name="scheduler"      ref="schedulerFactory"/>
        <property name="cronExpression" value="${{prefix}.{jobName}.cron:{cronDefault}}"/>
        <property name="enabled"        value="${{prefix}.{jobName}.enabled:true}"/>
        <property name="startDelay"     value="240000"/>
    </bean>

</beans>
```

Also add the import to `module-context.xml`:
```xml
<import resource="classpath:alfresco/module/{module-id}/context/scheduler-context.xml"/>
```

### 4. Unit Test
`{platform-project-root}/src/test/java/{package}/job/{JobName}JobExecuterTest.java`

```java
package {package}.job;

import org.alfresco.repo.transaction.RetryingTransactionHelper;
import org.alfresco.repo.transaction.RetryingTransactionHelper.RetryingTransactionCallback;
import org.alfresco.service.ServiceRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class {JobName}JobExecuterTest {

    @Mock
    private RetryingTransactionHelper retryingTransactionHelper;

    @Mock
    private ServiceRegistry serviceRegistry;

    private {JobName}JobExecuter executer;

    @BeforeEach
    void setUp() {
        executer = new {JobName}JobExecuter();
        executer.setRetryingTransactionHelper(retryingTransactionHelper);
        executer.setServiceRegistry(serviceRegistry);
    }

    @Test
    void execute_runsInsideTransaction() {
        when(retryingTransactionHelper.doInTransaction(
                any(RetryingTransactionCallback.class), anyBoolean(), anyBoolean()))
            .thenReturn(null);

        executer.execute();

        verify(retryingTransactionHelper)
            .doInTransaction(any(RetryingTransactionCallback.class), anyBoolean(), anyBoolean());
    }
}
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Derive it as
  `{platform-artifactId}` from Section 2 or from `<artifactId>` in the platform `pom.xml`.
  **Never use the full `module.id` property value (e.g. `com.someco.scheduled-jobs`) as the
  directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Job class naming: `{JobName}Job.java`; Executer class naming: `{JobName}JobExecuter.java`
- Bean IDs: `{prefix}.{jobName}Executer`, `{prefix}.{jobName}JobDetail`, `{prefix}.{jobName}Trigger`
- Cron expression format: Quartz 6-field (`seconds minutes hours dayOfMonth month dayOfWeek`)
  — e.g. `0 0 0 * * ?` (midnight daily), `0 0/30 * * * ?` (every 30 minutes)
- Cron and enabled flag **must** use property placeholders with sensible defaults
- `startDelay` must be at least `240000` ms to allow ACS to fully initialise before first run
- Never annotate job or executer classes with `@Transactional`
- Never use `@Scheduled` (Spring annotation) in a Platform JAR
- Never use `Thread.sleep()` in job execution — it blocks the Quartz thread pool
- Always verify node existence with `NodeService.exists()` before acting on a `NodeRef`
- Never generate scheduled job classes inside the Event Handler project
- After generating files, invoke the `content-model-validator` skill if the job modifies
  content types or aspects
