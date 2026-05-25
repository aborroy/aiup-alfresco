---
description: "Generate Alfresco content model XML and Spring context file from requirements."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /content-model — Content Model Generator

Generate Alfresco content model files based on requirements.

## Input
Read `REQUIREMENTS.md` (or use "$ARGUMENTS" as input) to extract content model requirements and
resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).

- If Section 2 contains no `Platform JAR` project, stop and explain that `/content-model` only
  applies to the in-process repository addon project.

## Output Files

### 1. Content Model XML
Create `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/model/content-model.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<model name="{prefix}:contentModel" xmlns="http://www.alfresco.org/model/dictionary/1.0">
    <description>...</description>
    <version>1.0</version>
    <imports>
        <import uri="http://www.alfresco.org/model/dictionary/1.0" prefix="d"/>
        <import uri="http://www.alfresco.org/model/content/1.0" prefix="cm"/>
    </imports>
    <namespaces>
        <namespace uri="http://www.{company}.com/model/{prefix}/1.0" prefix="{prefix}"/>
    </namespaces>
    <!-- types and aspects here -->
</model>
```

### 2. Spring Context
Create `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/bootstrap-context.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans" ...>
    <bean id="{prefix}.dictionaryBootstrap"
          parent="dictionaryModelBootstrap"
          depends-on="dictionaryBootstrap">
        <property name="models">
            <list>
                <value>alfresco/module/{module-id}/model/content-model.xml</value>
            </list>
        </property>
    </bean>
</beans>
```

### 3. Model Constants Interface
Create `{platform-project-root}/src/main/java/{package}/model/{Name}Model.java`:

```java
package {package}.model;

import org.alfresco.service.namespace.QName;

/**
 * Constants for the {prefix} content model.
 *
 * Use these constants everywhere instead of constructing QNames inline.
 * The two-argument QName.createQName(URI, localName) form is safe at class-load
 * time because it does not require a registered namespace prefix resolver.
 */
public interface {Name}Model {

    String NAMESPACE_URI = "http://www.{company}.com/model/{prefix}/1.0";
    String NAMESPACE_PREFIX = "{prefix}";

    // --- Types ---
    QName TYPE_{TYPE_LOCAL_NAME_UPPER} = QName.createQName(NAMESPACE_URI, "{typeLocalName}");

    // --- Aspects ---
    QName ASPECT_{ASPECT_LOCAL_NAME_UPPER} = QName.createQName(NAMESPACE_URI, "{aspectLocalName}");

    // --- Properties ---
    QName PROP_{PROP_LOCAL_NAME_UPPER} = QName.createQName(NAMESPACE_URI, "{propLocalName}");

    // --- Associations ---
    QName ASSOC_{ASSOC_LOCAL_NAME_UPPER} = QName.createQName(NAMESPACE_URI, "{assocLocalName}");
}
```

**Rules:**
- Generate one `QName` constant per type, aspect, property, and association declared in the model
- Constant name format: `{KIND}_{LOCAL_NAME_IN_UPPER_SNAKE_CASE}` where `KIND` is `TYPE`, `ASPECT`, `PROP`, or `ASSOC`
- This is a Java `interface` — all fields are implicitly `public static final`; do NOT use `class`
- Always use the **two-argument** form `QName.createQName(NAMESPACE_URI, localName)` — never the shorthand `QName.createQName("{prefix}:{localName}")` which requires a registered namespace resolver at class-load time
- Place in package `{java-package}.model` (e.g. `com.acme.extensions.model`)
- Filename: `{PascalCasePrefix}Model.java` (e.g. prefix `acme` → `AcmeModel.java`)
- Never expose this interface as a Spring bean — it is a pure Java constant holder

## Conventions
- `{module-id}` is the Platform JAR **artifactId** exactly as declared in `module.properties` under `module.id` minus the `{groupId}.` prefix — i.e. the bare artifact ID (e.g. `content-types`, not `com.someco.content-types`). Read it from `<artifactId>` in the platform `pom.xml`, or derive it as `{platform-artifactId}` from Section 2 of `REQUIREMENTS.md`. **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Follow namespace naming from AGENTS.md
- Use `cm:content` as default parent for document types
- Use `cm:folder` as default parent for folder types
- Every property must specify a valid `d:` data type
- Include constraints where requirements specify them
- Never generate content model files inside the Event Handler project

## Validation
After generating files, invoke the `content-model-validator` skill to validate the output.
