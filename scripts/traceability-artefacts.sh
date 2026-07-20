#!/usr/bin/env bash
# Shared artefact classification for post-generate traceability hooks (Claude + Cursor).
# Sets ARTEFACT_TYPE when FILE_PATH matches a generated AIUP output pattern.
# Returns 0 when classified, 1 otherwise.

classify_traceability_artefact() {
    local file_path="$1"
    ARTEFACT_TYPE=""

    case "$file_path" in
        *-model*.xml|*content-model*.xml|*-context.xml|*bootstrap-context.xml)
            ARTEFACT_TYPE="content-model"
            ;;
        *.desc.xml|*.get.js|*.get.java|*.post.js|*.post.java|*.get.json.ftl|*.post.json.ftl)
            ARTEFACT_TYPE="web-script"
            ;;
        *Behaviour.java|*behavior*.xml|*service-context.xml)
            ARTEFACT_TYPE="behaviour"
            ;;
        *ActionExecuter.java)
            ARTEFACT_TYPE="action"
            ;;
        */job/*Job.java|*/job/*JobExecuter.java|*scheduler-context.xml)
            ARTEFACT_TYPE="scheduled-job"
            ;;
        *BootstrapLoader.java)
            ARTEFACT_TYPE="bootstrap-loader"
            ;;
        */condition/*Condition.java)
            ARTEFACT_TYPE="rule-condition"
            ;;
        *Patch.java|*patch-context.xml)
            ARTEFACT_TYPE="repository-patch"
            ;;
        *.bpmn|*-workflow-model.xml)
            ARTEFACT_TYPE="workflow"
            ;;
        *_engine_config.json|*TransformEngine*.java|*CustomTransformer*.java)
            ARTEFACT_TYPE="transform"
            ;;
        *.plugin.json|*/aca-extension/*)
            ARTEFACT_TYPE="aca-extension"
            ;;
        *share-config-custom.xml)
            ARTEFACT_TYPE="share-config"
            ;;
        *compose.yaml|*Dockerfile)
            ARTEFACT_TYPE="docker-compose"
            ;;
        *IT.java|*/http-tests/*.sh|http-tests/*.sh)
            ARTEFACT_TYPE="test"
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}
