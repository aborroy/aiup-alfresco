---
description: "Register a custom rendition definition (Platform JAR) and, when no built-in transform covers the required source/target mimetype pair, scaffold a custom Transform Engine (Spring Boot, Out-of-Process). Optionally registers a new MIME type."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /transforms — Transform & Rendition Generator

> **Two deployment targets, one command.**
> - The **rendition definition** deploys inside the ACS Platform JAR.
> - The **custom Transform Engine** (when needed) deploys as a separate Spring Boot service,
>   following the same SPI as `https://github.com/aborroy/alf-tengine-convert2md`.
>
> **Always check the built-in transforms first.** `alfresco-transform-core-aio` ships
> ImageMagick, LibreOffice, PDFRenderer, and Tika. Only scaffold a custom engine when the
> required source→target mimetype pair is not covered by those engines.

## Built-in transforms (alfresco-transform-core-aio 5.4.0)

| Engine | Common source formats | Common target formats |
|--------|-----------------------|-----------------------|
| ImageMagick | image/\* (jpeg, png, gif, tiff, bmp, raw…) | image/jpeg, image/png, image/gif, image/tiff, image/bmp |
| LibreOffice | application/msword, .openxmlformats-officedocument.\*, .oasis.opendocument.\*, text/csv, .ms-excel… | application/pdf, text/plain, image/png, text/html |
| PDFRenderer | application/pdf | image/png |
| Tika | application/pdf, application/msword, .ms-\*, text/\*, audio/\*, video/\* | text/plain, text/html (metadata extraction) |

---

## Input

Read `REQUIREMENTS.md` to identify transform/rendition requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that the rendition
     definition requires a Platform JAR.

2. Read Section 7 (Behaviour Requirements) sub-section "Transform and rendition requirements".
   - If none are present, stop and ask the user to run `/requirements` first (or provide a
     description as `$ARGUMENTS`).

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only; `{name}-platform/` for Mixed
   - `{module-id}` — bare artifactId (e.g. `my-extension`); **never** the full `module.id` value
   - `{prefix}` — the namespace prefix from Section 5

4. Derive from transform requirements:
   - `{renditionName}` — camelCase rendition identifier (e.g. `pdfPreview`, `customThumb`)
   - `{sourceMimetype}` — source MIME type
   - `{targetMimetype}` — target MIME type
   - `{transformOptions}` — map of option key/value pairs
   - `{newMimetype}` — only if the source or target MIME type is unknown to ACS
   - `{engineName}` — camelCase engine name (e.g. `markdown`), only if a custom engine is needed
   - `{EngineName}` — PascalCase engine name (e.g. `Markdown`)
   - `{engine-queue}` — ActiveMQ queue name: `{engineName}-engine-queue`
   - `{engine-artifact}` — Maven artifactId of the engine project (e.g. `sc-markdown-engine`)

---

## Output Files

### Always generated — Rendition Definition (Platform JAR)

#### 1a. Rendition Context XML
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/rendition-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!--
        Custom rendition — ACS 26.1 Rendition Service 2.
        Auto-registers with renditionDefinitionRegistry2 via constructor.
        ACS routes the request to the engine that advertises {sourceMimetype} → {targetMimetype}.
    -->
    <bean id="{prefix}.rendition.{renditionName}"
          class="org.alfresco.repo.rendition2.RenditionDefinition2Impl">
        <constructor-arg name="renditionName"  value="{renditionName}"/>
        <constructor-arg name="targetMimetype" value="{targetMimetype}"/>
        <constructor-arg name="transformOptions">
            <map>
                <!-- Add options matching what the target engine accepts -->
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
- Use `class="org.alfresco.repo.rendition2.RenditionDefinition2Impl"` — ACS 26.1 Rendition
  Service 2. Never use the legacy `RenditionDefinition` class.
- Always pass `registry` ref pointing at `renditionDefinitionRegistry2`. The constructor
  auto-registers the rendition; no explicit `register()` call is needed.
- Always include a `timeout` entry referencing `${system.thumbnail.definition.default.timeoutMs}`.
- `transformOptions` keys must match what the target engine declares in its `engine_config.json`.

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
`alfresco/extension/mimetype/` on the classpath — no Spring import or bean needed.

---

### Generated only when a custom engine is required

A custom engine is a **standalone Spring Boot project** that implements the Alfresco
Transform Core SPI. The main class, HTTP endpoints, and ActiveMQ wiring are all provided
by `alfresco-base-t-engine` — you only write the engine declaration and the conversion logic.

#### 2a. Engine Project POM
`{engine-artifact}/pom.xml`

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
    <artifactId>{engine-artifact}</artifactId>
    <version>1.0.0-SNAPSHOT</version>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <!-- Provides TransformEngine SPI, HTTP endpoints, ActiveMQ wiring, and Application main class -->
        <dependency>
            <groupId>org.alfresco</groupId>
            <artifactId>alfresco-base-t-engine</artifactId>
            <version>5.4.0</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <!-- Main class comes from alfresco-base-t-engine, not this project -->
                    <mainClass>org.alfresco.transform.base.Application</mainClass>
                </configuration>
                <executions>
                    <execution>
                        <goals><goal>repackage</goal></goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>

    <repositories>
        <repository>
            <id>alfresco-public</id>
            <url>https://artifacts.alfresco.com/nexus/content/groups/public</url>
        </repository>
    </repositories>

</project>
```

> **Do NOT generate an `Application.java`**. The main class `org.alfresco.transform.base.Application`
> is provided by `alfresco-base-t-engine`. Generating a duplicate causes a startup conflict.
>
> **The `<repositories>` block is mandatory.** `alfresco-transform-core` and `alfresco-base-t-engine`
> are on Alfresco Nexus (`https://artifacts.alfresco.com/nexus/content/groups/public`), not Maven
> Central. Omitting it causes `Non-resolvable parent POM` build failure inside Docker.

#### 2b. TransformEngine Bean
`{engine-artifact}/src/main/java/{package}/transform/{EngineName}Engine.java`

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
        // Use a representative sample file from src/main/resources/
        return new ProbeTransform(
            "sample.{src-ext}", "{sourceMimetype}", "{targetMimetype}",
            java.util.Map.of(),
            1024, 16, 400, 10240,
            (60 * 30) + 1, (60 * 15) + 20
        );
    }
}
```

#### 2c. CustomTransformer Bean
`{engine-artifact}/src/main/java/{package}/transform/{EngineName}Transformer.java`

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
        // Read from inputStream, write converted content to outputStream.
        // transformOptions contains the parameters declared in {engineName}_engine_config.json.
        throw new UnsupportedOperationException(
            "Implement {EngineName} conversion logic here");
    }
}
```

#### 2d. Engine Config JSON
`{engine-artifact}/src/main/resources/{engineName}_engine_config.json`

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

#### 2e. Application Properties
`{engine-artifact}/src/main/resources/application.yml`

```yaml
spring:
  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 50MB

# ActiveMQ queue name — must match TRANSFORMER_QUEUE_{ENGINE_UPPER} in transform-router config
queue:
  engineRequestQueue: {engine-queue}

transform:
  core:
    version: 5.4.0
```

#### 2f. Dockerfile
`{engine-artifact}/Dockerfile`

```dockerfile
# syntax=docker/dockerfile:1.4
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn dependency:go-offline -q
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn clean package -DskipTests -q

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

> If the conversion logic requires additional runtimes (Python, native libraries, etc.),
> use a multi-stage build with the appropriate base image for stage 2, as shown in
> `https://github.com/aborroy/alf-tengine-convert2md`.

#### 2g. Compose additions (add to project compose.yaml)

ACS 26.1 Community uses a **Transform Router** (`alfresco-transform-router`). The engine
registers with the router — not directly with ACS.

```yaml
  # Custom engine service
  {engine-artifact}:
    build:
      context: ./{engine-artifact}
      dockerfile: Dockerfile
    environment:
      JAVA_OPTS: "-Xms256m -Xmx512m"
      ACTIVEMQ_URL: "nio://activemq:61616"
      ACTIVEMQ_USER: ${ACTIVEMQ_USER}
      ACTIVEMQ_PASSWORD: ${ACTIVEMQ_PASSWORD}
      FILE_STORE_URL: "http://shared-file-store:8099/alfresco/api/-default-/private/sfs/versions/1/file"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8090/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    depends_on:
      activemq:
        condition: service_healthy
      shared-file-store:
        condition: service_healthy

  # Transform Router — tell it about the new engine
  transform-router:
    environment:
      {ENGINE_UPPER}_URL: "http://{engine-artifact}:8090"
      TRANSFORMER_QUEUE_{ENGINE_UPPER}: "{engine-queue}"
```

Where `{ENGINE_UPPER}` is the engine name in UPPER_CASE (e.g. `MARKDOWN`).

---

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Never use the full
  `module.id` property value as the directory name.
- Rendition names: camelCase (e.g. `pdfPreview`, `customThumb200`).
- Engine name: camelCase for code/config (e.g. `markdown`), UPPER_CASE for env vars (e.g. `MARKDOWN`).
- Queue name: `{engineName}-engine-queue` — must match `queue.engineRequestQueue` in `application.yml`
  and `TRANSFORMER_QUEUE_{ENGINE_UPPER}` in the transform-router environment.
- **Do not generate `Application.java`** — it comes from `alfresco-base-t-engine`.
- Engine exposes port `8090`.
- Never add `localTransform.{name}.url` to ACS JAVA_OPTS for ACS 26.1 — that is the ACS 25.x
  Community pattern. ACS 26.1 uses the Transform Router.
- Never build a custom engine for a mimetype pair already handled by `alfresco-transform-core-aio`.
