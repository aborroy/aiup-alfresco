# Requirements: Scheduled Jobs

## 1. Business Purpose
Archive inactive documents nightly: query for all `sc:doc` nodes where `sc:isActive=false`
and `cm:modified` is older than 30 days, move them to an archive folder, and log a summary.
The job must be cluster-safe and configurable without redeployment.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: scheduled-jobs
- **Platform module**: scheduled-jobs
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an administrator, a nightly job automatically moves inactive documents to an archive folder.
- As an administrator, I can disable the job without redeployment by setting a property.
- As an administrator, I can change the schedule without redeployment by setting a cron expression.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:doc` extends `cm:content`
  - `sc:isActive` (d:boolean, optional)

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Scheduled job requirements
- **Job name**: `contentArchiver`
- **Default cron**: `0 0 0 * * ?` (midnight daily)
- **Enabled by default**: true
- **Logic**: find `sc:doc` nodes where `sc:isActive=false` and `cm:modified` older than 30 days;
  move each to `/app:company_home/cm:Archive`; log count at INFO level.
- Must use `AbstractScheduledLockedJob` for cluster safety.
- Must wrap repository operations in `RetryingTransactionHelper`.
- Cron expression configurable via `sc.contentArchiver.cron` property.
- Enabled flag configurable via `sc.contentArchiver.enabled` property.

## 8. Deployment Requirements
- Platform JAR with scheduler beans registered in `scheduler-context.xml`.
- `scheduler-context.xml` imported from `module-context.xml`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | ContentArchiverJob.java, ContentArchiverJobExecuter.java | ContentArchiverJobExecuterTest.java |
| US-02 | scheduler-context.xml (enabled property) | |
| US-03 | scheduler-context.xml (cron property) | |
