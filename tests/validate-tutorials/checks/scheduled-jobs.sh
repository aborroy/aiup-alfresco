#!/usr/bin/env bash
# Checker: scheduled-jobs
# Usage: scheduled-jobs.sh <generated-dir> <reference-dir>
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=../lib/checks.sh
source "$SCRIPT_DIR/../lib/checks.sh"

GEN="$1"

printf '\n=== scheduled-jobs ===\n'

# ---- Common checks ----
assert_grep_any_file "alfresco-sdk-aggregator" "$GEN" "pom.xml" "a pom.xml uses alfresco-sdk-aggregator parent"

MODULE_PROPS=$(find "$GEN" -name "module.properties" | head -1)
if [[ -n "$MODULE_PROPS" ]]; then
    assert_grep "module.id" "$MODULE_PROPS" "module.properties has module.id"
    assert_grep "module.version" "$MODULE_PROPS" "module.properties has module.version"
else
    _fail "module.properties exists" "not found under $GEN"
fi

MODULE_CTX=$(find "$GEN" -name "module-context.xml" | head -1)
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "context" "$MODULE_CTX" "module-context.xml has a context import"
else
    _fail "module-context.xml exists" "not found under $GEN"
fi

# ---- Job class ----
JOB_JAVA=$(find "$GEN" -name "*Job.java" | grep -v "Executer\|IT\|Test" | head -1) || true
assert_file_exists "${JOB_JAVA:-/nonexistent}" "*Job.java exists"
if [[ -n "$JOB_JAVA" ]]; then
    assert_grep "AbstractScheduledLockedJob" "$JOB_JAVA" "Job class extends AbstractScheduledLockedJob"
    assert_grep "executeJob" "$JOB_JAVA" "Job class implements executeJob()"
    assert_not_grep "@Scheduled" "$JOB_JAVA" "Job class does not use forbidden @Scheduled"
    assert_not_grep "@Transactional" "$JOB_JAVA" "Job class does not use forbidden @Transactional"
fi

# ---- Executer class ----
EXECUTER_JAVA=$(find "$GEN" -name "*JobExecuter.java" | head -1) || true
assert_file_exists "${EXECUTER_JAVA:-/nonexistent}" "*JobExecuter.java exists"
if [[ -n "$EXECUTER_JAVA" ]]; then
    assert_grep "RetryingTransactionHelper" "$EXECUTER_JAVA" "Executer uses RetryingTransactionHelper"
    assert_grep "doInTransaction" "$EXECUTER_JAVA" "Executer wraps logic in doInTransaction()"
    assert_not_grep "@Transactional" "$EXECUTER_JAVA" "Executer does not use forbidden @Transactional"
    assert_not_grep "@Scheduled" "$EXECUTER_JAVA" "Executer does not use forbidden @Scheduled"
fi

# ---- Scheduler context XML ----
SCHED_CTX=$(find "$GEN" -name "scheduler-context.xml" | head -1) || true
assert_file_exists "${SCHED_CTX:-/nonexistent}" "scheduler-context.xml exists"
if [[ -n "$SCHED_CTX" ]]; then
    assert_xml_wellformed "$SCHED_CTX" "scheduler-context.xml is well-formed XML"
    assert_grep "AbstractScheduledLockedJob\|JobDetailFactoryBean" "$SCHED_CTX" "scheduler-context.xml declares job detail"
    assert_grep "CronTriggerBean" "$SCHED_CTX" "scheduler-context.xml uses CronTriggerBean"
    assert_grep "schedulerFactory" "$SCHED_CTX" "scheduler-context.xml references schedulerFactory"
    assert_grep "cronExpression" "$SCHED_CTX" "scheduler-context.xml declares cronExpression property"
    assert_grep "enabled" "$SCHED_CTX" "scheduler-context.xml declares enabled property"
    assert_grep "startDelay" "$SCHED_CTX" "scheduler-context.xml sets startDelay"
    assert_not_grep "redeploy" "$SCHED_CTX" "scheduler-context.xml has no workflow redeploy pattern"
fi

# ---- module-context.xml imports scheduler-context ----
if [[ -n "$MODULE_CTX" ]]; then
    assert_grep "scheduler-context" "$MODULE_CTX" "module-context.xml imports scheduler-context.xml"
fi

# ---- Unit test ----
TEST_JAVA=$(find "$GEN" -name "*JobExecuterTest.java" | head -1) || true
assert_file_exists "${TEST_JAVA:-/nonexistent}" "*JobExecuterTest.java exists"
if [[ -n "$TEST_JAVA" ]]; then
    assert_grep "RetryingTransactionHelper" "$TEST_JAVA" "test mocks RetryingTransactionHelper"
    assert_grep "@ExtendWith(MockitoExtension.class)\|@RunWith(MockitoJUnitRunner" "$TEST_JAVA" "test uses Mockito extension"
fi

print_summary "scheduled-jobs"
exit_with_status
