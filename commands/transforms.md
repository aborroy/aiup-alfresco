---
description: "Register a custom rendition definition (Platform JAR) and, when no built-in transform covers the required source/target mimetype pair, scaffold a custom Transform Engine (Spring Boot, Out-of-Process). Optionally registers a new MIME type."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /transforms — Transform & Rendition Generator

> **Two deployment targets, one command.**
> - The **rendition definition** deploys inside the ACS Platform JAR.
> - The **custom transform engine** (when needed) deploys as a separate Spring Boot container.
>
> The AIO container (`alfresco-transform-core-aio:5.4.0`) ships ImageMagick, LibreOffice,
> PDFRenderer, and Tika. **Check whether a built-in transform already covers your
> source/target mimetype pair** before scaffolding a custom engine.

## Built-in transforms (alfresco-transform-core-aio)

The following conversions are available **without a custom engine**:

| Engine | Common source formats | Common target formats |
|--------|-----------------------|-----------------------|
| ImageMagick | image/\* (jpeg, png, gif, tiff, bmp, raw formats…) | image/jpeg, image/png, image/gif, image/tiff, image/bmp |
| LibreOffice | application/msword, application/vnd.openxmlformats-officedocument.\*, application/vnd.oasis.opendocument.\*, text/csv, application/vnd.ms-excel… | application/pdf, text/plain, image/png, text/html |
| PDFRenderer | application/pdf | image/png |
| Tika | application/pdf, application/msword, application/vnd.ms-\*, text/\*, audio/\*, video/\* | text/plain, text/html, application/json (metadata) |

If the required source→target pair is covered above, **only generate the rendition
definition**. No custom engine project is needed.

If the pair is **not** in the list above, scaffold a custom engine alongside the
rendition definition.

---

## Input

Read `REQUIREMENTS.md` to identify transform/rendition requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that the rendition
     definition part of `/transforms` only applies to the Platform JAR.

2. Read Section 7 (Behaviour Requirements) sub-section "Transform and rendition requirements".
   - If none are present, stop and ask the user to run `/requirements` first (or provide a
     description as `$ARGUMENTS`).

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only; `{name}-platform/` for Mixed
   - `{module-id}` — bare artifactId (e.g. `my-extension`); **never** the full `module.id` value
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix from Section 5

4. Derive from transform requirements:
   - `{renditionName}` — camelCase rendition identifier (e.g. `pdfPreview`, `customThumb`)
   - `{sourceMimetype}` — source MIME type (e.g. `application/pdf`)
   - `{targetMimetype}` — target MIME type (e.g. `image/png`)
   - `{transformOptions}` — map of option key/value pairs (resize dimensions, timeout, etc.)
   - `{newMimetype}` — only if the source or target is a MIME type not known to ACS
   - `{engineName}` — camelCase engine name, only if a custom engine is needed

---

## Output Files

### Always generated: Rendition Definition (Platform JAR)

#### 1a. Rendition Context XML
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/rendition-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!--
        Custom rendition definition — ACS 26.1 Rendition Service 2.
        Auto-registers with renditionDefinitionRegistry2 via constructor injection.
        ACS routes the transform request to whichever engine supports
        {sourceMimetype} → {targetMimetype}.
    -->
    <bean id="{prefix}.rendition.{renditionName}"
          class="org.alfresco.repo.rendition2.RenditionDefinition2Impl">
        <constructor-arg name="renditionName"   value="{renditionName}"/>
        <constructor-arg name="targetMimetype"  value="{targetMimetype}"/>
        <constructor-arg name="transformOptions">
            <map>
                <!-- Resize options (for image targets) -->
                <entry key="resizeWidth"         value="200"/>
                <entry key="resizeHeight"        value="200"/>
                <entry key="maintainAspectRatio" value="true"/>
                <entry key="allowEnlargement"    value="false"/>
                <entry key="thumbnail"           value="true"/>
                <!-- Timeout — always specify; use the system property -->
                <entry key="timeout"
                       value="${system.thumbnail.definition.default.timeoutMs}"/>
            </map>
        </constructor-arg>
        <constructor-arg name="registry" ref="renditionDefinitionRegistry2"/>
    </bean>

</beans>
```

Add the import to `module-context.xml`:
```xml
<import resource="classpath:alfresco/module/{module-id}/context/rendition-context.xml"/>
```

Key rules for the rendition bean:
- Use `class="org.alfresco.repo.rendition2.RenditionDefinition2Impl"` — this is the ACS 26.1
  Rendition Service 2 implementation. Do **not** use the legacy `RenditionDefinition` class.
- Always pass `registry` ref pointing at `renditionDefinitionRegistry2` — the constructor
  auto-registers the rendition; no explicit `register()` call is needed.
- Always include a `timeout` entry referencing `${system.thumbnail.definition.default.timeoutMs}`.
- `transformOptions` keys must match what the target transform engine accepts (see built-in
  table above or the custom engine's `engine_config.json`).

#### 1b. MIME Type Extension XML (only when source or target is a new MIME type)
`{platform-project-root}/src/main/resources/alfresco/extension/mimetype/mimetypes-extension-map.xml`

```xml
<alfresco-config area="mimetype-map">
    <config evaluator="string-compare" condition="Mimetype Map">
        <mimetypes>
            <mimetype mimetype="{newMimetype}" display="{Human Readable Name}">
                <extension>{file-extension}</extension>
            </mimetype>
        </mimetypes>
    </config>
</alfresco-config>
```

This file uses **Alfresco config XML format** (not Spring beans). ACS auto-discovers it from
`alfresco/extension/mimetype/` on the classpath. No Spring import or bean registration is needed.

---

### Generated only when a custom engine is required

#### 2a. Engine Project POM
`{engine-name}/pom.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.alfresco</groupId>
        <artifactId>alfresco-transform-core</artifactId>
        <version>5.4.0</version>
    </parent>

    <groupId>{groupId}</groupId>
    <artifactId>{engine-name}</artifactId>
    <version>1.0.0-SNAPSHOT</version>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

#### 2b. Spring Boot Application Class
`{engine-name}/src/main/java/{package}/transform/Application.java`

```java
package {package}.transform;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

#### 2c. TransformEngine Bean
`{engine-name}/src/main/java/{package}/transform/{EngineName}Engine.java`

```java
package {package}.transform;

import org.alfresco.transform.base.TransformEngine;
import org.alfresco.transform.base.probes.ProbeTransform;
import org.alfresco.transform.config.TransformConfig;
import org.alfresco.transform.config.reader.TransformConfigResourceReader;
import org.springframework.stereotype.Component;

@Component
public class {EngineName}Engine implements TransformEngine {

    private static final String ENGINE_NAME = "{engineName}";
    private static final String CONFIG_PATH = "classpath:{engineName}_engine_config.json";

    private final TransformConfigResourceReader configReader;

    public {EngineName}Engine(TransformConfigResourceReader configReader) {
        this.configReader = configReader;
    }

    @Override
    public String getTransformEngineName() {
        return ENGINE_NAME;
    }

    @Override
    public String getStartupMessage() {
        return "Startup " + ENGINE_NAME;
    }

    @Override
    public TransformConfig getTransformConfig() {
        return configReader.read(CONFIG_PATH);
    }

    @Override
    public ProbeTransform getProbeTransform() {
        return new ProbeTransform(
            "sample.{src-ext}", "{sourceMimetype}", "{targetMimetype}",
            java.util.Map.of(),
            1024, 16, 400, 10240,
            (60 * 30) + 1, (60 * 15) + 20
        );
    }
}
```

#### 2d. CustomTransformer Bean
`{engine-name}/src/main/java/{package}/transform/{EngineName}Transformer.java`

```java
package {package}.transform;

import org.alfresco.transform.base.CustomTransformer;
import org.alfresco.transform.base.TransformManager;
import org.springframework.stereotype.Component;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Map;

@Component
public class {EngineName}Transformer implements CustomTransformer {

    @Override
    public String getTransformerName() {
        return "{engineName}";
    }

    @Override
    public void transform(String sourceMimetype,
                          InputStream inputStream,
                          String targetMimetype,
                          OutputStream outputStream,
                          Map<String, String> transformOptions,
                          TransformManager transformManager) throws Exception {
        // Implement the conversion logic here.
        // Read from inputStream, write result to outputStream.
        // transformOptions contains the parameters declared in engine_config.json.
        throw new UnsupportedOperationException("Implement transform logic here");
    }
}
```

#### 2e. Engine Config JSON
`{engine-name}/src/main/resources/{engineName}_engine_config.json`

```json
{
  "transformOptions": {
    "{engineName}Options": [
      { "value": { "name": "timeout" } }
    ]
  },
  "transformers": [
    {
      "transformerName": "{engineName}",
      "supportedSourceAndTargetList": [
        {
          "sourceMediaType": "{sourceMimetype}",
          "targetMediaType": "{targetMimetype}"
        }
      ],
      "transformOptions": [ "{engineName}Options" ]
    }
  ]
}
```

#### 2f. Dockerfile
`{engine-name}/Dockerfile`

```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn clean package -DskipTests -q

FROM eclipse-temurin:17-jre-jammy
ARG GROUP_NAME=alfresco
ARG GROUP_ID=1000
ARG USER_NAME=transform
ARG USER_ID=33001
RUN groupadd -g ${GROUP_ID} ${GROUP_NAME} && \
    useradd -u ${USER_ID} -g ${GROUP_NAME} -m ${USER_NAME}
WORKDIR /app
COPY --from=build /workspace/target/*.jar /app/app.jar
RUN chown -R ${USER_NAME}:${GROUP_NAME} /app
USER ${USER_NAME}
EXPOSE 8090
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

#### 2g. Docker Compose service snippet (add to project compose.yaml)

```yaml
  {engine-name}:
    build:
      context: ./{engine-name}
      dockerfile: Dockerfile
    ports:
      - "8090:8090"
    environment:
      JAVA_OPTS: "-Xms256m -Xmx512m"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8090/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

Also add `depends_on: {engine-name}: condition: service_healthy` to the `alfresco` service.

---

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Never use the full
  `module.id` property value as the directory name.
- `{platform-project-root}` is `.` for Platform JAR only; `{name}-platform/` for Mixed mode.
- Rendition names: camelCase (e.g. `pdfPreview`, `customThumb200`).
- Always include a `timeout` transform option referencing the system property.
- MIME type config XML goes in `alfresco/extension/mimetype/` — never in a Spring context.
- Custom engine parent POM: `org.alfresco:alfresco-transform-core:5.4.0`.
- Custom engine transformer name must match `getTransformerName()`, `engine_config.json`
  `transformerName`, and the rendition definition's implicit routing.
- Engine exposes port `8090` (default Transform Service port).
- Never hardcode transform routing to a specific engine in the Platform JAR — ACS discovers
  available transforms from registered engines at startup.
- Never generate a custom engine for mimetype pairs already covered by `alfresco-transform-core-aio`.
