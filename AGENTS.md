# Alfresco Extension Development — Project Conventions

This file defines the conventions that every AI agent must follow when generating or reviewing Alfresco extension code for the `aiup-alfresco` project.

---

## Technology Stack

| Component | Version | Notes |
|-----------|---------|-------|
| Alfresco Content Services (ACS) | 26.1 | Community or Enterprise |
| Maven In-Process SDK | 4.15.0 (`alfresco-sdk-aggregator`) | Platform JAR, deployed inside ACS — [alfresco-sdk](https://github.com/Alfresco/alfresco-sdk) |
| Spring Boot Out-of-Process SDK | 7.2.0 | External Spring Boot app — [alfresco-java-sdk](https://github.com/Alfresco/alfresco-java-sdk) |
| Java | 17+ | LTS, required by ACS 26.1 |
| Spring Boot | 3.x | Managed by SDK parent POM |
| Spring Framework | 6.x | Managed by Spring Boot |
| Maven | 3.9+ | Build tool |
| Docker Compose | v2 | No `version:` key in compose files |
| PostgreSQL | 17.9 | Default database |
| Apache ActiveMQ | 6.2.1 | Event messaging — authentication required |
| Search Enterprise (OpenSearch) | 4.0 | **Recommended** — OpenSearch 2.x or Elasticsearch 8.x backend |
| Search Services (Solr) | 2.0.18 | Alternative — Solr-based, community default |
| Transform Service | 5.4.0 | AIO (all-in-one) for development |

### Docker Images (ACS 26.1)

Choose one search profile per deployment — do not mix them.

#### Profile A — Search Enterprise / OpenSearch (recommended)

```
alfresco/alfresco-content-repository-community:26.1.0
alfresco/alfresco-share:26.1.0
opensearchproject/opensearch:2.x
postgres:17.9
docker.io/alfresco/alfresco-activemq:6.2.1-jre17-rockylinux8
alfresco/alfresco-transform-core-aio:5.4.0
```

#### Profile B — Search Services / Solr

```
alfresco/alfresco-content-repository-community:26.1.0
alfresco/alfresco-share:26.1.0
alfresco/alfresco-search-services:2.0.18
postgres:17.9
docker.io/alfresco/alfresco-activemq:6.2.1-jre17-rockylinux8
alfresco/alfresco-transform-core-aio:5.4.0
```

### Maven In-Process SDK Coordinates (ACS 26.1)

```xml
<parent>
    <groupId>org.alfresco.maven</groupId>
    <artifactId>alfresco-sdk-aggregator</artifactId>
    <version>4.15.0</version>
</parent>
```

> `alfresco-sdk-aggregator` is the correct artifact ID for SDK 4.x.
> `alfresco-sdk-parent` is an obsolete artifact last published in 2016 (max version 2.2.0) — never use it.
> SDK 4.15.0 is published on Maven Central; no extra `<repository>` entry is needed in `pom.xml`
> for the parent itself.  The Alfresco Nexus repository (`https://artifacts.alfresco.com/nexus/content/groups/public`)
> is still required for runtime dependencies (`alfresco-repository`, `alfresco-remote-api`, etc.)
> and is configured automatically by the `alfresco-sdk-aggregator` parent POM.
> The parent does **not** supply dependency versions for platform libraries in a standalone Platform JAR.
> Generated POMs must also import `${alfresco.bomDependency.artifactId}` in `<dependencyManagement>`
> using `${alfresco.platform.version}`.

Required dependency-management import:
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.alfresco</groupId>
            <artifactId>${alfresco.bomDependency.artifactId}</artifactId>
            <version>${alfresco.platform.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

Key dependencies:
```xml
<dependency>
    <groupId>org.alfresco</groupId>
    <artifactId>alfresco-remote-api</artifactId>
    <scope>provided</scope>
</dependency>
<dependency>
    <groupId>org.alfresco</groupId>
    <artifactId>alfresco-repository</artifactId>
    <scope>provided</scope>
</dependency>
<dependency>
    <groupId>org.alfresco.surf</groupId>
    <artifactId>spring-webscripts</artifactId>
    <scope>provided</scope>
</dependency>
```

### Spring Boot Out-of-Process SDK Coordinates (ACS 26.1)

```xml
<parent>
    <groupId>org.alfresco</groupId>
    <artifactId>alfresco-java-sdk</artifactId>
    <version>7.2.0</version>
</parent>
```

Key dependency (event-driven integration):
```xml
<dependency>
    <groupId>org.alfresco</groupId>
    <artifactId>alfresco-java-event-api-spring-boot-starter</artifactId>
    <version>7.2.0</version>
</dependency>
```

> The Out-of-Process SDK runs as a standalone Spring Boot application that connects to ACS via the Event API (ActiveMQ) and REST API. It does **not** deploy a JAR into Alfresco.

---

## Project Layout

Standard project layouts for repository, Share-tier, and event-driven extensions:

> **Note:** `aiup-alfresco` may scaffold a Platform JAR project, a Share JAR project, an Event Handler project, or a mixed repository containing two or more of those deployables.

### Deployment Boundary

- Treat the **Platform JAR / AMP**, **Share JAR / AMP**, and **Event Handler** as separate deployables.
- If a solution needs multiple deployables, scaffold a mixed repository with sibling projects/modules such as `{name}-platform/`, `{name}-share/`, and `{name}-events/`.
- In mixed mode, the repo root may contain the aggregator `pom.xml`, `compose.yaml`, `REQUIREMENTS.md`, and shared docs/scripts, but no runtime `src/` tree.
- Never place Spring Boot `Application` classes, `application.properties`, or `@AlfrescoEventListener` code in the Platform JAR project.
- Never place `alfresco/web-extension/...`, `alfresco/site-webscripts/...`, Share evaluators, or Aikau artefacts in the Platform JAR project.
- Never place `alfresco/module/...`, content model files, behaviours, actions, or Web Scripts in the Event Handler project.
- Never place `alfresco/module/...`, repository Spring contexts, content model files, behaviours, actions, or repo Web Scripts in the Share project.
- Never place Spring Boot `Application` classes, `application.properties`, or `@AlfrescoEventListener` code in the Share project.
- Never try to combine repository addon code, Share-tier code, and Spring Boot event code in the same Maven module or the same deployable artifact.

```
{project-name}/
├── pom.xml                                          # Parent POM (repo root or aggregator)
├── compose.yaml                                     # Docker Compose for local dev
├── REQUIREMENTS.md                                  # Generated by /requirements
├── src/                                             # Present only for single-project layouts
│   ├── main/
│   │   ├── java/{package-path}/                     # e.g. com/acme/extensions/
│   │   └── resources/
│   └── test/
│       └── java/{package-path}/
├── {name}-platform/                                 # Present in mixed layouts when repo code is needed
│   └── src/main/resources/alfresco/module/{module-id}/
├── {name}-share/                                    # Present in mixed layouts when Share-tier UI is needed
│   └── src/main/resources/alfresco/
│       ├── web-extension/
│       └── site-webscripts/
└── {name}-events/                                   # Present in mixed layouts when async handling is needed
    └── src/main/resources/application.properties
```

### Platform JAR Layout

```
src/
├── main/
│   ├── java/{package-path}/
│   │   ├── model/                                   # Content model constants interfaces
│   │   ├── webscript/                               # Java-backed repo Web Script controllers
│   │   ├── behaviour/                               # Behaviour/policy classes
│   │   ├── action/                                  # Action executors
│   │   ├── workflow/                                # Java task listeners (created by /workflow)
│   │   └── service/                                 # Business logic services
│   └── resources/
│       └── alfresco/
│           ├── extension/
│           │   └── templates/webscripts/            # Repo Web Script descriptors & Freemarker templates
│           └── module/{module-id}/
│               ├── module.properties                # Module descriptor
│               ├── module-context.xml               # Module Spring context (imports)
│               ├── context/
│               │   ├── bootstrap-context.xml        # Dictionary + workflow bootstrap beans
│               │   ├── service-context.xml          # Service/behaviour/action beans
│               │   └── webscript-context.xml        # Repo Web Script beans
│               ├── model/
│               │   └── content-model.xml
│               ├── workflow/
│               │   └── {processName}.bpmn
│               └── messages/
│                   └── {processName}Workflow.properties
└── test/
    └── java/{package-path}/
        └── {Name}IT.java
```

### Module Properties

```properties
module.id={groupId}.{artifactId}
module.title={Human Readable Title}
module.description={Description}
module.version=1.0.0
module.repo.version.min=26.1
```

---

## Naming Conventions

### Namespace
- **URI pattern**: `http://www.{company}.com/model/{prefix}/{version}`
  - Example: `http://www.acme.com/model/acme/1.0`
- **Prefix**: lowercase, 2-6 alphanumeric characters
  - Example: `acme`
- **Reserved prefixes** (never use): `sys`, `cm`, `app`, `usr`, `act`, `wcm`, `wca`, `lnk`, `fm`, `dl`, `ia`, `smf`, `imap`, `emailserver`, `bpm`, `wcmwf`, `trx`, `stcp`, `alf`, `d`, `r`

### Content Model
- **Model name**: `{prefix}:contentModel` — e.g. `acme:contentModel`
- **Type names**: `{prefix}:{camelCaseTypeName}` — e.g. `acme:invoice`
- **Aspect names**: `{prefix}:{camelCaseAspectName}` — e.g. `acme:auditable`
- **Property names**: `{prefix}:{camelCasePropertyName}` — e.g. `acme:invoiceNumber`
- **Association names**: `{prefix}:{camelCaseAssocName}` — e.g. `acme:relatedDocuments`
- **Constraint names**: `{prefix}:{camelCaseConstraintName}` — e.g. `acme:invoiceStatusOptions`

### Java
- **Package**: `{groupId}.{artifactId}` — e.g. `com.acme.extensions`
- **Behaviour classes**: `{Name}Behaviour.java`
- **Action classes**: `{Name}ActionExecuter.java`
- **Web Script classes**: `{Name}WebScript.java` (extending `DeclarativeWebScript` or `AbstractWebScript`)
- **Services**: `{Name}Service.java` (interface), `{Name}ServiceImpl.java`

### Spring Beans
- **Bean IDs**: `{prefix}.{beanName}` — e.g. `acme.invoiceBehaviour`
- **Action bean parent**: `action-executer`
- **Dictionary bootstrap parent**: `dictionaryModelBootstrap`

### Web Script API Paths
- **Custom Web Scripts**: `/api/{prefix}/{resource}`
- Resource names: plural nouns, kebab-case
- No verbs in paths
- Web Script descriptor file: `{resource}.{method}.desc.xml` — e.g. `invoices.get.desc.xml`
- Web Script template file: `{resource}.{method}.json.ftl` — e.g. `invoices.get.json.ftl`

### Web Script Descriptor Properties

Every descriptor must explicitly declare the following fields — do not rely on defaults:

| Field | Options | Guidance |
|-------|---------|----------|
| `<authentication>` | `none`, `guest`, `user`, `admin` | Use the minimum level required; most API scripts use `user` |
| `<format default="">` | `json`, `html`, `atom`, `rss`; or `any` for negotiation | Set an explicit default; omitting it forces callers to specify the format in the URL |
| `<transaction> ` | `none`, `required`, `requiresnew` | Read-only scripts: `required` (read tx); write scripts: `required`; avoid `none` unless the script truly performs no repository operations |
| `<cache>` | `never`, `revalidate`, or nested `<never>`, `<public>`, `<private>` | Default to `never` for API responses; set `revalidate` only for stable, non-personal data |

Example minimal descriptor:
```xml
<webscript>
  <shortname>List Invoices</shortname>
  <url>/api/acme/invoices</url>
  <authentication>user</authentication>
  <format default="json"/>
  <transaction>required</transaction>
  <cache>
    <never>true</never>
  </cache>
</webscript>
```

### Docker
- **Service names**: lowercase, hyphenated — e.g. `alfresco`, `transform-core-aio`
- **Volume names**: `{project}-{service}-data` — e.g. `myproject-postgres-data`

---

## Coding Standards

### Java
- Java 17+ features: records, sealed classes, pattern matching, text blocks where appropriate
- Use constructor injection for Java-configured beans; use setter injection where XML bean wiring is required; avoid field injection unless there is a strong reason
- Use `NodeService`, `ContentService`, `SearchService`, `PermissionService` from `org.alfresco.service`
- Use `NodeRef` for node references, never raw string UUIDs in service calls
- Use `QName.createQName()` for QName construction, with namespace URI from `QNameModule`
- Use `RetryingTransactionHelper` for operations that need transaction retry
- Prefer `AuthenticationUtil.runAs()` over `setFullyAuthenticatedUser()` — and only when justified

### Spring Configuration

**Maven In-Process SDK** — the boundary between Java and XML configuration is functional, not stylistic:

- **Use XML** for any bean that plugs into an Alfresco module integration point: `DictionaryModelBootstrap`, behaviour policy registration, action executer registration, Web Script bean declarations, and anything wired via `module-context.xml` sub-contexts. Alfresco's module loading mechanism expects these at specific XML locations.
- **Use Java `@Configuration`** for internal service wiring that has no Alfresco integration point — e.g. your own `@Service` / `@Component` beans, helper utilities, or SDK-managed beans that do not need to be registered with an Alfresco subsystem.
- `module-context.xml` is the entry point imported by the SDK; it should only import sub-context XML files, never define beans directly.

**Spring Boot Out-of-Process SDK** — use standard Spring Boot conventions throughout: `@Configuration`, `@EventListener`, `@SpringBootApplication`. No XML required.

### Error Handling
- Throw `AlfrescoRuntimeException` for unrecoverable Alfresco errors
- Use `WebScriptException` with HTTP status codes in Web Script controllers
- Log exceptions at `ERROR` level with full context; log business events at `INFO`

### Paging (REST)
All collection responses must use the Alfresco paging envelope:
```json
{
  "list": {
    "pagination": {
      "count": 10,
      "hasMoreItems": true,
      "totalItems": 42,
      "skipCount": 0,
      "maxItems": 10
    },
    "entries": [
      { "entry": { ... } }
    ]
  }
}
```

---

## Testing Conventions

### Unit Tests
- JUnit 5
- Mockito for mocking Alfresco services
- Test class: `{Name}Test.java`
- One test class per production class

### Integration Tests
- Alfresco SDK integration test runner
- Test class: `{Name}IT.java` (suffix `IT`)
- Run against a live ACS container via Docker
- Use `@TestMethodOrder(MethodOrderer.OrderAnnotation.class)` for sequential tests
- Clean up test data in `@AfterAll` or `@AfterEach`

### HTTP API Tests
- Use any HTTP client (curl, HTTPie, Bruno, etc.) — no tool mandated
- Cover: happy path, validation errors (400), not found (404), unauthorized (401)
- Keep test scripts in `http-tests/` as plain HTTP request files or shell scripts

---

## Docker / Containerisation

### Compose File Conventions
- Format: Docker Compose v2 (no `version:` key)
- Every service has a `healthcheck` block
- `depends_on` uses `condition: service_healthy`
- Named volumes for all persistent data
- Environment variables in the compose file, not `.env` (for transparency)

### Environment Variables
- `ALFRESCO_HOST` — ACS base URL (e.g. `http://localhost:8080`); used by tests
- `ALFRESCO_USERNAME` / `ALFRESCO_PASSWORD` — credentials for tests
- `JAVA_OPTS` — JVM options for Alfresco and Share containers
- `ACTIVEMQ_USER` / `ACTIVEMQ_PASSWORD` — ActiveMQ broker credentials; must match across all services
- `SOLR_ALFRESCO_SECRET` — shared secret between ACS and Solr; required in healthchecks and ACS config *(Search Services profile only)*

### Healthcheck Endpoints

| Service | Check |
|---------|-------|
| Alfresco | `curl -f http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-` |
| Share | `curl -f -u admin:$${ALFRESCO_PASSWORD} http://localhost:8080/share` |
| PostgreSQL | `pg_isready -d alfresco -U alfresco` |
| ActiveMQ | `curl -sf -u $${ACTIVEMQ_USER:-admin}:$${ACTIVEMQ_PASSWORD:-admin} http://localhost:8161/admin/ > /dev/null` |
| Solr *(Search Services)* | `curl -f -H "X-Alfresco-Search-Secret: $${SOLR_ALFRESCO_SECRET}" http://localhost:8983/solr/alfresco/admin/ping` |
| OpenSearch / Elasticsearch *(Search Enterprise)* | `curl -s http://localhost:9200/_cluster/health \| grep -q 'green\|yellow'` |
| Transform | `curl -f http://localhost:8090/ready` |

### Encryption Keystore — Required Setup for ACS 26.1

ACS 26.1 ships with a JCEKS keystore inside the image at
`/usr/local/tomcat/shared/classes/alfresco/extension/keystore/keystore`.
Use it directly — **no custom keystore generation or host volume mount is needed**.

Only `JAVA_TOOL_OPTIONS` is required:

```yaml
environment:
  JAVA_TOOL_OPTIONS: >-
    -Dencryption.keystore.type=JCEKS
    -Dencryption.cipherAlgorithm=DESede/CBC/PKCS5Padding
    -Dencryption.keyAlgorithm=DESede
    -Dencryption.keystore.location=/usr/local/tomcat/shared/classes/alfresco/extension/keystore/keystore
    -Dmetadata-keystore.password=mp6yc0UD9e
    -Dmetadata-keystore.aliases=metadata
    -Dmetadata-keystore.metadata.password=oKIWzVdEdA
    -Dmetadata-keystore.metadata.algorithm=DESede
```

> **Common pitfall**: the metadata key password is `oKIWzVdEdA` (not `oKIWzOIvdD`).
> Using the wrong password causes `02240004 Failed to retrieve keys from keystore: Given final block not properly padded`.
> Omitting `JAVA_TOOL_OPTIONS` entirely causes `02240000 Unable to get secret key: no key information is provided`.

### Extension Deployment
Mount the built JAR into the Alfresco container:
```yaml
volumes:
  - ./target/{artifact}.jar:/usr/local/tomcat/webapps/alfresco/WEB-INF/lib/{artifact}.jar
```
Or build a custom image:
```dockerfile
FROM alfresco/alfresco-content-repository-community:26.1.0
COPY target/{artifact}.jar /usr/local/tomcat/webapps/alfresco/WEB-INF/lib/
```

### Docker Desktop on macOS — Testcontainers Compatibility

Docker Desktop 29.x on macOS raised the minimum accepted Docker API version to **1.40**. The docker-java library bundled with Testcontainers defaults to an older version and receives an HTTP 400 response, causing Testcontainers to report *"Could not find valid Docker environment"* even when Docker is running.

**One-time developer-machine setup (macOS only):**

```bash
# 1. Tell docker-java to use API 1.44
echo "api.version=1.44" >> ~/.docker-java.properties

# 2. Force Unix socket strategy and remove any stale TCP endpoint entries
cat > ~/.testcontainers.properties <<'EOF'
testcontainers.reuse.enable=true
docker.client.strategy=org.testcontainers.dockerclient.UnixSocketClientProviderStrategy
EOF
```

**In every `pom.xml` that runs Testcontainers** — add to the Failsafe plugin `<configuration>` so CI processes and fresh checkouts also work:

```xml
<environmentVariables>
    <API_VERSION>1.44</API_VERSION>
</environmentVariables>
```

> **Why `API_VERSION`, not `DOCKER_API_VERSION`**: docker-java 3.3.x defines the constant as `API_VERSION` (not `DOCKER_API_VERSION`). The properties file key is `api.version`. Setting the wrong name is silently ignored.

**Always annotate the Testcontainers test class with `disabledWithoutDocker = true`** so builds without Docker skip gracefully instead of failing:

```java
@Testcontainers(disabledWithoutDocker = true)
```

---

## Security Model

### Permission Model
- Always use `PermissionService` to check/set permissions — never bypass
- Use `AccessStatus.ALLOWED` checks before operations on behalf of users
- `AuthenticationUtil.runAsSystem` — only for bootstrap or system-level operations, never for user-facing code
- Custom permissions: define in `permissionDefinitions.xml` if needed

### Search Enterprise (Elasticsearch)
- ACL fields `sys_acl` and `sys_racl` must be indexed for permission-aware search
- Verify ACL indexing in Elasticsearch index configuration

### Authentication
- **Preferred**: OAuth2 with an external identity provider (e.g. Keycloak) — use this for new production deployments
- **Compatibility fallback**: ticket-based authentication where project constraints require it (e.g. legacy clients, systems that cannot support OAuth2)
- Never hardcode credentials in Java code or properties files committed to VCS

---

## Event Model

> The Maven In-Process SDK does **not** consume events — the repository only produces them. Event consumption is exclusively for the **Spring Boot Out-of-Process SDK**.

### Alfresco Java Event API (Out-of-Process SDK only)
- Dependency: `org.alfresco:alfresco-java-event-api-spring-boot-starter`
- ActiveMQ default topic: `alfresco.repo.event2`
- Event types: `NodeCreatedEvent`, `NodeUpdatedEvent`, `NodeDeletedEvent`, `ContentCreatedEvent`, `ContentUpdatedEvent`, `ContentDeletedEvent`
- Consumer group naming: `{prefix}.{purpose}` — e.g. `acme.invoiceProcessor`

### ActiveMQ Configuration

ActiveMQ 6.2.1 requires authentication. There are two distinct layers of variable names — do not confuse them:

| Layer | Variable | Description |
|-------|----------|-------------|
| **Project convention** | `ACTIVEMQ_USER` | Defined once in the compose file; holds the chosen username value |
| **Project convention** | `ACTIVEMQ_PASSWORD` | Defined once in the compose file; holds the chosen password value |
| **ActiveMQ container** | `ACTIVEMQ_USERNAME` | Image-specific variable name the broker reads; mapped from `ACTIVEMQ_USER` |
| **ActiveMQ container** | `ACTIVEMQ_PASSWORD` | Same name as the project variable — no mapping needed |
| **Spring clients** | `SPRING_ACTIVEMQ_USER` | Variable name Spring Boot reads; mapped from `ACTIVEMQ_USER` |
| **Spring clients** | `SPRING_ACTIVEMQ_PASSWORD` | Variable name Spring Boot reads; mapped from `ACTIVEMQ_PASSWORD` |

```yaml
activemq:
  image: docker.io/alfresco/alfresco-activemq:6.2.1-jre17-rockylinux8
  environment:
    ACTIVEMQ_OPTS: "-Xms512m -Xmx1g"
    ACTIVEMQ_USERNAME: ${ACTIVEMQ_USER}      # image expects ACTIVEMQ_USERNAME
    ACTIVEMQ_PASSWORD: ${ACTIVEMQ_PASSWORD}
```

Every service that connects to ActiveMQ (ACS, Transform Service, Share, Out-of-Process extensions) must set:
```yaml
environment:
  SPRING_ACTIVEMQ_USER: ${ACTIVEMQ_USER}       # Spring expects SPRING_ACTIVEMQ_USER
  SPRING_ACTIVEMQ_PASSWORD: ${ACTIVEMQ_PASSWORD}
```

- Define `ACTIVEMQ_USER` and `ACTIVEMQ_PASSWORD` once in the compose file (no `.env` file)
- Use the same values consistently across all services — mismatches cause silent connection failures

---

## Transform & Rendition Model

> ACS 26.1 uses an **out-of-process Transform Service** architecture. Rendition definitions
> live in the Platform JAR; actual conversion logic runs in a separate container.
> Before building a custom transform engine, verify that the required source→target mimetype
> pair is not already covered by `alfresco-transform-core-aio` (ImageMagick, LibreOffice,
> PDFRenderer, Tika).

### Technology

| Component | Version | Role |
|-----------|---------|------|
| Rendition Service 2 | ACS 26.1 built-in | Routes rendition requests to transforms |
| `alfresco-transform-core-aio` | 5.4.0 | All-in-one container: ImageMagick, LibreOffice, PDFRenderer, Tika |
| Custom engine parent POM | `org.alfresco:alfresco-transform-core:5.4.0` | SDK for building custom engines |

### File Placement

| Artifact | Location |
|----------|----------|
| Rendition definition bean | `src/main/resources/alfresco/module/{module-id}/context/rendition-context.xml` (Platform JAR) |
| MIME type registration | `src/main/resources/alfresco/extension/mimetype/mimetypes-extension-map.xml` (Platform JAR) |
| Custom engine `TransformEngine` | `{engine-name}/src/main/java/{package}/transform/{EngineName}Engine.java` (separate project) |
| Custom engine `CustomTransformer` | `{engine-name}/src/main/java/{package}/transform/{EngineName}Transformer.java` (separate project) |
| Engine config JSON | `{engine-name}/src/main/resources/{engineName}_engine_config.json` (separate project) |
| Dockerfile | `{engine-name}/Dockerfile` (separate project) |

### Rendition Definition Pattern (Platform JAR)

```xml
<bean id="{prefix}.rendition.{renditionName}"
      class="org.alfresco.repo.rendition2.RenditionDefinition2Impl">
    <constructor-arg name="renditionName"   value="{renditionName}"/>
    <constructor-arg name="targetMimetype"  value="{targetMimetype}"/>
    <constructor-arg name="transformOptions">
        <map>
            <entry key="resizeWidth"         value="200"/>
            <entry key="resizeHeight"        value="200"/>
            <entry key="maintainAspectRatio" value="true"/>
            <entry key="thumbnail"           value="true"/>
            <entry key="timeout"
                   value="${system.thumbnail.definition.default.timeoutMs}"/>
        </map>
    </constructor-arg>
    <constructor-arg name="registry" ref="renditionDefinitionRegistry2"/>
</bean>
```

- Use `RenditionDefinition2Impl` — the ACS 26.1 Rendition Service 2 class.
- Pass `registry` ref pointing at `renditionDefinitionRegistry2` — auto-registers on construction.
- Always include a `timeout` entry using the system property.

### MIME Type Registration (Platform JAR)

```xml
<!-- alfresco/extension/mimetype/mimetypes-extension-map.xml -->
<alfresco-config area="mimetype-map">
    <config evaluator="string-compare" condition="Mimetype Map">
        <mimetypes>
            <mimetype mimetype="{newMimetype}" display="{Display Name}">
                <extension>{ext}</extension>
            </mimetype>
        </mimetypes>
    </config>
</alfresco-config>
```

This file uses Alfresco config XML format (not Spring). ACS auto-discovers it from
`alfresco/extension/mimetype/` on the classpath — no `<import>` in `module-context.xml` needed.

### Custom Engine Pattern (Spring Boot, separate project)

A custom engine is a standalone Spring Boot project with parent `org.alfresco:alfresco-transform-core:5.4.0`.
It implements two Spring `@Component` beans:
- `TransformEngine` — declares engine name, startup message, config path, and health-probe transform.
- `CustomTransformer` — implements `transform(sourceMimetype, inputStream, targetMimetype, outputStream, options, manager)`.

**Do NOT generate `Application.java`** — the main class `org.alfresco.transform.base.Application`
is provided by the `alfresco-base-t-engine` dependency. Declare it in the `spring-boot-maven-plugin`
`<mainClass>` configuration instead.

The key dependency providing HTTP endpoints, ActiveMQ wiring, and the Application class is:
```xml
<dependency>
    <groupId>org.alfresco</groupId>
    <artifactId>alfresco-base-t-engine</artifactId>
    <version>5.4.0</version>
</dependency>
```

The engine name in `getTransformerName()` must match the `transformerName` in `engine_config.json`
and the queue name prefix in `application.yml` (`queue.engineRequestQueue: {engineName}-engine-queue`).

**ACS 26.1 Integration (Transform Router pattern):**
- The engine registers with `transform-router`, not directly with ACS.
- In `compose.yaml`, add to `transform-router` environment:
  - `{ENGINE_UPPER}_URL: http://{engine-service}:8090`
  - `TRANSFORMER_QUEUE_{ENGINE_UPPER}: {engineName}-engine-queue`
- The engine service itself needs `ACTIVEMQ_URL`, `ACTIVEMQ_USER`, `ACTIVEMQ_PASSWORD`, and `FILE_STORE_URL`.
- **Never add `localTransform.{name}.url`** to ACS JAVA_OPTS for ACS 26.1 — that is the ACS 25.x pattern.

Engine exposes port `8090`.

---

## Repository Patch Model

> The Maven In-Process SDK (Platform JAR) is the only deployment target for repository patches.
> They run inside the ACS JVM on startup, migrate **existing** data between module versions, and are
> recorded permanently in `alf_applied_patch`. Use a bootstrap loader (`/bootstrap-loader`) for
> **initial** data creation; use a patch for **migration** of existing content.

### Technology

ACS 26.1 manages patches via `org.alfresco.repo.admin.patch.AbstractPatch`. The patch service
checks `alf_applied_patch` on every startup and skips already-applied patches. Schema version
integers (`fixesFromSchema`, `fixesToSchema`, `targetSchema`) control applicability. The
`targetSchema` for ACS 26.1 (alfresco-repository 7.43) is **5026**.

### File Placement

| Artifact | Path |
|----------|------|
| Patch class | `src/main/java/{package}/patch/{PatchName}Patch.java` |
| Patch context XML | `src/main/resources/alfresco/module/{module-id}/context/patch-context.xml` |
| Unit test | `src/test/java/{package}/patch/{PatchName}PatchTest.java` |

### Naming Conventions

- **Class name**: `{PatchName}Patch` — extends `AbstractPatch`
- **Patch ID**: `patch.{module-id}.{camelCaseName}` — globally unique, used as the key in `alf_applied_patch`
- **Bean ID**: same as the patch ID (`patch.{module-id}.{camelCaseName}`)
- **Context file**: `patch-context.xml` — separate from `bootstrap-context.xml` and `service-context.xml`

### Spring Registration Pattern

```xml
<bean id="patch.{module-id}.{camelCaseName}"
      class="{package}.patch.{PatchName}Patch"
      parent="basePatch">
    <property name="id"              value="patch.{module-id}.{camelCaseName}"/>
    <property name="description"     value="What this patch does"/>
    <property name="fixesFromSchema" value="0"/>
    <property name="fixesToSchema"   value="5026"/>
    <property name="targetSchema"    value="5026"/>
</bean>
```

- `parent="basePatch"` auto-injects: `nodeService`, `searchService`, `transactionService`, `namespaceService`.
- Register `patch-context.xml` by adding an `<import>` to `module-context.xml`.
- To declare a dependency on another patch: `<property name="dependsOn"><list><ref bean="..."/></list></property>`.

### Java Class Pattern

```java
public class {PatchName}Patch extends AbstractPatch {
    @Override
    protected String applyInternal() throws Exception {
        // use inherited: nodeService, searchService, transactionService, namespaceService
        // return a human-readable summary of what was done
        return "Patch applied: N nodes updated";
    }
}
```

- Extend `AbstractPatch` and override `applyInternal()` — this is the only method to implement.
- Do **not** declare `nodeService`, `searchService`, etc. as fields — use the `protected` inherited fields.
- Always close `ResultSet` in a `finally` block.
- Always check `nodeService.exists(nodeRef)` before acting — concurrent deletes can invalidate nodes.
- Do **not** add `@Transactional` or wrap in `retryingTransactionHelper` — `AbstractPatch` manages the transaction.
- Use `SearchService.LANGUAGE_FTS_ALFRESCO` — never `LANGUAGE_LUCENE`.

### Schema Version Values

| Use case | `fixesFromSchema` | `fixesToSchema` | `targetSchema` |
|----------|-------------------|-----------------|----------------|
| Apply on every ACS 26.1 install | `0` | `5026` | `5026` |
| Apply only when upgrading from a specific version | schema of previous version | `5026` | `5026` |

### Re-running a Patch

The patch is keyed in `alf_applied_patch` by the `id` property value. To re-run in development,
delete the row from `alf_applied_patch` where `id = '{patch-id}'`, or change the `id` property to a
new value. Never change the `id` in production without understanding the idempotency implications.

---

## Rule Condition Model

> The Maven In-Process SDK (Platform JAR) is the only deployment target for custom rule condition evaluators. They extend ACS's folder Rules engine and are available to both rule configuration and the Action Service REST API.

### Technology

ACS 26.1 ships `org.alfresco.repo.action.evaluator.ActionConditionEvaluatorAbstractBase` as the standard base class for all condition evaluators. The parent Spring bean `action-condition-evaluator` registers the evaluator with the Action Service via its `init()` method.

### File Placement

| Artifact | Path |
|----------|------|
| Condition evaluator class | `src/main/java/{package}/action/condition/{ConditionName}Condition.java` |
| Spring bean registration | `src/main/resources/alfresco/module/{module-id}/context/service-context.xml` |
| Unit test | `src/test/java/{package}/action/condition/{ConditionName}ConditionTest.java` |

### Naming Conventions

- **Class name**: `{ConditionName}Condition` — in package `{package}.action.condition`
- **Condition ID constant**: `public static final String NAME = "{prefix}-{condition-name}"` — kebab-case, prefix-scoped (e.g. `sc-has-aspect`)
- **Parameter constants**: `public static final String PARAM_{UPPER} = "{prefix}-{param-name}"`
- **Bean ID**: `{prefix}.{conditionName}Condition`

### Spring Registration Pattern

```xml
<bean id="{prefix}.{conditionName}Condition"
      class="{package}.action.condition.{ConditionName}Condition"
      parent="action-condition-evaluator">
    <property name="nodeService" ref="NodeService"/>
</bean>
```

- Use `parent="action-condition-evaluator"` — this handles `init()` and registration with the Action Service automatically.
- Conditions and action executers share `service-context.xml` — no separate context file is needed.

### Java Class Pattern

```java
public class {ConditionName}Condition extends ActionConditionEvaluatorAbstractBase {
    public static final String NAME = "{prefix}-{condition-name}";

    @Override
    protected boolean evaluateImpl(ActionCondition actionCondition, NodeRef actionedUponNodeRef) {
        if (!nodeService.exists(actionedUponNodeRef)) return false;
        // condition logic — return true if satisfied
    }

    @Override
    protected void addParameterDefinitions(List<ParameterDefinition> paramList) {
        // declare parameters; omit override if condition takes no parameters
    }
    // setter injection only
}
```

- Extend `ActionConditionEvaluatorAbstractBase`, not the interface `ActionConditionEvaluator` directly.
- Override `evaluateImpl(ActionCondition, NodeRef)` — **not** `evaluate()` (which is implemented by the abstract base).
- Always guard with `nodeService.exists()` before operating on the node.
- Read parameter values with `actionCondition.getParameterValue(PARAM_NAME)`.

### Share UI Exposure

Registering the bean makes the condition available programmatically. To show it in the **Share Rules UI** dropdown, a `share-config-custom.xml` entry in a Share JAR is also needed — generate that with `/share-config`.

---

## Bootstrap Loader Model

> The Maven In-Process SDK (Platform JAR) is the only deployment target for bootstrap loaders. They run inside the ACS JVM during module startup, exactly once per module version.

### Technology

ACS 26.1 tracks module component execution in the repository database. The correct base class is `org.alfresco.repo.module.AbstractModuleComponent`. The framework records each execution keyed by `moduleId + name + sinceVersion`, preventing re-execution on restart.

**Do NOT** use `@PostConstruct`, `init-method`, or `ApplicationReadyEvent` for repository data initialisation — they fire on every server restart and create duplicates.

### File Placement

| Artifact | Path |
|----------|------|
| Bootstrap loader class | `src/main/java/{package}/bootstrap/{LoaderName}BootstrapLoader.java` |
| Bootstrap context entry | `src/main/resources/alfresco/module/{module-id}/context/bootstrap-context.xml` |
| Unit test | `src/test/java/{package}/bootstrap/{LoaderName}BootstrapLoaderTest.java` |

### Naming Conventions

- **Class name**: `{LoaderName}BootstrapLoader` — extends `AbstractModuleComponent`
- **Bean ID**: `{groupId}.{LoaderName}BootstrapLoader` — groupId prefix ensures global uniqueness across modules
- `moduleId` property: must exactly match the value in `module.properties`
- `sinceVersion`: module version string at which this loader was introduced (e.g. `1.0`)
- `appliesFromVersion`: always `0.99` — ensures the loader also runs on `1.0-SNAPSHOT` builds

### Spring Registration Pattern

```xml
<bean id="{groupId}.{LoaderName}BootstrapLoader"
      class="{package}.bootstrap.{LoaderName}BootstrapLoader"
      parent="module.baseComponent">
    <property name="moduleId"           value="{module-id}"/>
    <property name="name"               value="{LoaderName}BootstrapLoader"/>
    <property name="description"        value="Bootstrap initial data for {module-id}"/>
    <property name="sinceVersion"       value="1.0"/>
    <property name="appliesFromVersion" value="0.99"/>
    <property name="nodeService"        ref="NodeService"/>
    <property name="fileFolderService"  ref="FileFolderService"/>
    <property name="nodeLocatorService" ref="nodeLocatorService"/>
</bean>
```

- Place in `bootstrap-context.xml` (the same file as `dictionaryBootstrap` if content model exists).
- Do **not** add `depends-on="dictionaryBootstrap"` unless the loader references custom model types — the module framework already handles ordering.

### Java Class Pattern

```java
public class {LoaderName}BootstrapLoader extends AbstractModuleComponent {
    private static final Logger LOG = LoggerFactory.getLogger({LoaderName}BootstrapLoader.class);
    private NodeService nodeService;
    private FileFolderService fileFolderService;
    private NodeLocatorService nodeLocatorService;

    @Override
    protected void executeInternal() throws Throwable {
        NodeRef companyHome = nodeLocatorService.getNode("companyhome", null, null);
        // create folders / categories / reference data
    }
    // setter injection only — no @Autowired
}
```

- Extend `AbstractModuleComponent` and override `executeInternal()` — this is the only lifecycle method.
- Do **not** add `@Transactional` — the framework provides a transaction automatically.
- Do **not** wrap calls in `RetryingTransactionHelper` — already in a transaction.
- Always obtain Company Home via `nodeLocatorService.getNode("companyhome", null, null)` — never hardcode a `NodeRef`.
- Include `findOrCreateFolder()` helpers so the loader is safe to re-run in dev environments where the DB was reset without wiping the content store.

### Re-running a Loader

To re-run a loader after its first execution, **increment `sinceVersion`** in the bean definition and in `module.properties`. Never delete rows from `alf_applied_patch` or `alf_module_prop` manually.

---

## Scheduled Job Model

> The Maven In-Process SDK (Platform JAR) is the only deployment target for scheduled jobs. They run inside the ACS JVM using the embedded Quartz scheduler.

### Technology

ACS 26.1 embeds **Quartz 2.x** managed by the `schedulerFactory` bean. All scheduled jobs must use the Alfresco cluster-safe abstraction.

**Do NOT** use Spring's `@Scheduled` annotation in a Platform JAR. It is not wired to Quartz or the `JobLockService`, so it fires on every node in a cluster simultaneously.

### File Placement

| Artifact | Path |
|----------|------|
| Job class (Quartz entry point) | `src/main/java/{package}/job/{JobName}Job.java` |
| Executer class (business logic) | `src/main/java/{package}/job/{JobName}JobExecuter.java` |
| Scheduler Spring context | `src/main/resources/alfresco/module/{module-id}/context/scheduler-context.xml` |
| Unit test | `src/test/java/{package}/job/{JobName}JobExecuterTest.java` |

### Naming Conventions

- **Job class**: `{JobName}Job.java` — extends `AbstractScheduledLockedJob`
- **Executer class**: `{JobName}JobExecuter.java` — plain Spring bean, no Quartz dependency
- **Bean IDs**: `{prefix}.{jobName}Executer`, `{prefix}.{jobName}JobDetail`, `{prefix}.{jobName}Trigger`
- **Cron property key**: `{prefix}.{jobName}.cron` with a sensible default
- **Enabled property key**: `{prefix}.{jobName}.enabled` defaulting to `true`

### Spring Registration Pattern

```xml
<!-- Executer holds all business logic -->
<bean id="{prefix}.{jobName}Executer"
      class="{package}.job.{JobName}JobExecuter">
    <property name="retryingTransactionHelper" ref="retryingTransactionHelper"/>
    <property name="serviceRegistry"           ref="ServiceRegistry"/>
</bean>

<!-- Job detail wires Quartz to the executer -->
<bean id="{prefix}.{jobName}JobDetail"
      class="org.springframework.scheduling.quartz.JobDetailFactoryBean">
    <property name="jobClass" value="{package}.job.{JobName}Job"/>
    <property name="jobDataAsMap">
        <map>
            <entry key="executer" value-ref="{prefix}.{jobName}Executer"/>
        </map>
    </property>
</bean>

<!-- Trigger: cron and enabled are property-configurable with defaults -->
<bean id="{prefix}.{jobName}Trigger"
      class="org.alfresco.util.CronTriggerBean">
    <property name="jobDetail"      ref="{prefix}.{jobName}JobDetail"/>
    <property name="scheduler"      ref="schedulerFactory"/>
    <property name="cronExpression" value="${{prefix}.{jobName}.cron:{cronDefault}}"/>
    <property name="enabled"        value="${{prefix}.{jobName}.enabled:true}"/>
    <property name="startDelay"     value="240000"/>
</bean>
```

- `startDelay` must be at least `240000` ms (4 minutes) so ACS fully initialises before first execution.
- Cron expressions are Quartz 6-field format: `seconds minutes hours dayOfMonth month dayOfWeek`.
  Common examples: `0 0 0 * * ?` (midnight daily), `0 0/30 * * * ?` (every 30 minutes).
- Register `scheduler-context.xml` by adding an `<import>` to `module-context.xml`.

### Job Class Pattern

```java
public class {JobName}Job extends AbstractScheduledLockedJob {
    private {JobName}JobExecuter executer;

    @Override
    public void executeJob(JobExecutionContext context) throws JobExecutionException {
        executer.execute();
    }

    public void setExecuter({JobName}JobExecuter executer) {
        this.executer = executer;
    }
}
```

- The Job class must be **stateless** — no Alfresco service fields, no shared mutable state.
- `AbstractScheduledLockedJob` acquires a `JobLockService` lock before calling `executeJob()`,
  preventing concurrent execution on cluster nodes.

### Executer Class Pattern

```java
public class {JobName}JobExecuter {
    private RetryingTransactionHelper retryingTransactionHelper;
    private ServiceRegistry serviceRegistry;

    public void execute() {
        retryingTransactionHelper.doInTransaction(() -> {
            // business logic
            return null;
        }, false, true);
    }
    // setter injection only — no @Autowired
}
```

- Wrap every repository operation in `retryingTransactionHelper.doInTransaction()`.
- The executer is a plain POJO: no Quartz imports, no `@Transactional`. This makes it testable with Mockito without starting Quartz or ACS.

---

## Workflow Model

> The Maven In-Process SDK (Platform JAR) is the only deployment target for workflows. Workflows deploy into the ACS JVM alongside other platform code.

### Technology

ACS 26.1 embeds **Activiti 5.22.x** (via `alfresco-activiti-embedded`). All Activiti classes are available through `alfresco-repository` (`provided` scope) — no extra POM dependency is needed.

**Do NOT** use Activiti 6 or Flowable APIs (`org.flowable.*`). The engine ID registered with Alfresco's `WorkflowService` is `activiti`.

### File Placement

| Artifact | Path |
|----------|------|
| BPMN process definition | `src/main/resources/alfresco/module/{module-id}/workflow/{processName}.bpmn` |
| Workflow task content model | `src/main/resources/alfresco/module/{module-id}/model/{processName}-workflow-model.xml` |
| i18n message bundle | `src/main/resources/alfresco/module/{module-id}/messages/{processName}Workflow.properties` |
| Java task listener | `src/main/java/{package}/workflow/{Name}TaskListener.java` |

### Naming Conventions

- **Workflow namespace sub-prefix**: `{prefix}wf` — e.g. if the content model prefix is `acme`, the workflow prefix is `acmewf`
- **Workflow namespace URI**: `http://www.{company}.com/model/workflow/1.0`
- **Start task type**: `{prefix}wf:submit{ProcessName}Task` extending `bpm:startTask`
- **User task form types**: `{prefix}wf:activiti{TaskName}` extending `bpm:activitiOutcomeTask`
- **Outcome property**: `{prefix}wf:{taskName}Outcome` with a LIST constraint
- **BPMN process `id` attribute**: camelCase process name — e.g. `publishWhitepaper`
- **Process variable naming**: Alfresco maps content model property `{prefix}wf:{propName}` → process variable `{prefix}wf_{propName}` (colon replaced by underscore). Always use the **underscore form** in BPMN expressions, `execution.setVariable()`, and `task.getVariableLocal()` calls.

### Spring Bootstrap Pattern

Workflow BPMN definitions and workflow model XML are registered via a **`workflowDeployer`** parent bean — **not** `dictionaryModelBootstrap`.

```xml
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

- When a project also has a regular content model, use **two separate beans**: `{prefix}.dictionaryBootstrap` (parent `dictionaryModelBootstrap`) for the regular model, and `{prefix}.workflowBootstrap` (parent `workflowDeployer`) for workflow artifacts. Both can coexist in `bootstrap-context.xml`.
- Set `redeploy` to `false` on all `workflowDefinitions` entries — prevents re-deployment on every restart. To redeploy after a BPMN change, use the Workflow Console: `undeploy definition name {processName}`.

### Java Task Listener Pattern

- Implement `org.activiti.engine.delegate.TaskListener` (Activiti 5.x — do NOT use Flowable or Activiti 6 APIs)
- Retrieve `ServiceRegistry` via: `Context.getProcessEngineConfiguration().getBeans().get(ActivitiConstants.SERVICE_REGISTRY_BEAN_KEY)`
- `Context` and `ProcessEngineConfigurationImpl` are internal Activiti 5.x classes available at runtime via `alfresco-repository (provided)` — no extra dependency, but some IDEs may flag them as warnings
- Register in BPMN: `<activiti:taskListener event="create|complete|assignment" class="{FQN}"/>`
- Do **not** inject Spring beans via `@Autowired` in task listener classes — always use `ServiceRegistry` from the Activiti context

### Workflow Testing

Use the Alfresco Workflow REST API v1:

| Operation | Endpoint |
|-----------|----------|
| Start process | `POST /alfresco/api/-default-/public/workflow/versions/1/processes` |
| List tasks | `GET /alfresco/api/-default-/public/workflow/versions/1/tasks?assignee={user}` |
| Complete task | `POST /alfresco/api/-default-/public/workflow/versions/1/tasks/{taskId}` body `{"action":"complete","variables":[...]}` |
| Query process variables | `GET /alfresco/api/-default-/public/workflow/versions/1/processes/{processId}/variables` |
| Delete process (cleanup) | `DELETE /alfresco/api/-default-/public/workflow/versions/1/processes/{processId}` |

Always discover `processDefinitionId` dynamically from `GET /process-definitions?name={processName}` — never hardcode the version suffix (`:1:104`).

---

## Share UI Model

> Share-tier customizations are supported for legacy/customer-estate parity, not because Share is the preferred UI for ACS 26.1. When the request is really for ACA/ADF/custom frontend work, keep that outside the Share addon path.

### Deployment Boundary

- The Share tier is a separate deployable from the repository tier.
- Share addon artefacts belong in a dedicated Share project/module when the architecture includes both repo and Share work.
- Never write Share files under `alfresco/module/...`; that path is repository-only.
- Never write repository content model, behaviour, action, workflow, or repo Web Script files under the Share project.

### File Placement

| Artifact | Path |
|----------|------|
| Share config root | `src/main/resources/alfresco/web-extension/` |
| Main Share form config | `src/main/resources/alfresco/web-extension/share-config-custom.xml` |
| Surf extension metadata | `src/main/resources/alfresco/web-extension/site-data/extensions/{extensionName}.xml` |
| Share message bundles | `src/main/resources/alfresco/web-extension/messages/{bundle}.properties` |
| Surf / Aikau web-tier web scripts | `src/main/resources/alfresco/site-webscripts/{path}/...` |
| Java evaluators / helpers | `src/main/java/{package}/share/...` |

### Naming Conventions

- **Share project/module suffix**: `{artifactId}-share` in mixed layouts
- **Evaluator classes**: `{Name}Evaluator.java`
- **Surf extension files**: kebab-case or lower camel names that match page/component IDs consistently
- **Dashlet and page IDs**: stable, lowercase, project-prefixed identifiers
- **Message bundle keys**: project-prefixed and grouped by page/component/form purpose

### Guidance

- Use Share-tier generation only when the user explicitly targets Share, Surf, Aikau, dashlets, evaluators, or `share-config-custom.xml`
- If the request is only for repository functionality consumed by a UI, keep the code in the Platform JAR and expose it through existing repo-side commands
- If the request is for a modern frontend, recommend ACA/ADF/custom frontend instead of generating Share artefacts
- Share task forms are not the default workflow target in this repository; workflow APIs remain the primary generated path unless Share forms are explicitly requested
- For Surf work, keep page IDs, component URLs, and extension-module IDs aligned across `site-data/extensions` and `site-webscripts`
- Prefer extension modules and component insertion over direct replacement of existing Share pages unless replacement is explicitly required
- For Aikau work, prefer built-in widgets and explicit page-model composition before generating custom widget modules
- Keep Aikau page-model IDs, JS module paths, and message keys stable across descriptors, model scripts, and widget modules

### Forbidden Patterns

| Pattern | Reason | Alternative |
|---------|--------|-------------|
| Writing Share config into the Platform JAR project | Breaks deployment boundaries and packaging clarity | Put Share artefacts in the Share project/module |
| Writing repo artefacts into the Share project | Share cannot deploy repo module resources | Keep repo code under `alfresco/module/...` in the Platform JAR |
| Treating Share as the default UI for ACS 26.1 | Misstates the modern product direction | Use Share only when the requirement explicitly targets it |
| Using `/share/page/home` as a healthcheck target | Share 26.x does not expose it reliably | Use the Share root URL as documented in `commands/docker-compose.md` |
| Generating inconsistent Surf page/component/module IDs | Breaks Share page wiring and extension-module activation | Keep IDs and URLs stable across extension metadata and web scripts |
| Replacing built-in Share pages when extension modules would suffice | Increases fragility and upgrade risk | Prefer additive extension modules and component insertion |
| Generating unnecessary custom Aikau widgets when built-in widgets suffice | Increases maintenance cost and JS surface area | Prefer widget composition and existing Aikau services first |
| Embedding repository business rules in Aikau page-model JavaScript | Moves server-side logic into brittle client-side code | Keep business rules in repository APIs or repo-side commands |

---

## ACA / ADW Extension Model

> ACA/ADW extensions are **source drop-ins**, not npm packages. The extension folder is
> copied into an existing ACA or ADW source checkout and compiled as part of the host
> application's build. There is no Maven build, no Platform JAR, and no separate npm publish
> step. Reference: `https://github.com/aborroy/alfresco-content-lake-ui`

### Technology

| Component | Version | Role |
|-----------|---------|------|
| Angular | 19.x | Component framework |
| ADF (`@alfresco/adf-core`, `@alfresco/adf-extensions`) | 8.4.x | ACA/ADW component library and extension SPI |
| NgRx (`@ngrx/effects`) | — | Side-effect handling for plugin actions |
| `@alfresco/js-api` | — | Typed Alfresco REST API client |

### Extension Structure

```
{ext-name}/
├── src/
│   ├── assets/{ext-name}.plugin.json   # ADF extension manifest (JSON)
│   ├── lib/
│   │   ├── components/                 # Standalone Angular components
│   │   ├── services/                   # Injectable services using AppConfigService
│   │   ├── store/                      # NgRx actions + effects
│   │   └── models/                     # TypeScript interfaces only
│   ├── {ext-name}.module.ts            # provideExtension() + @NgModule compat shim
│   └── public-api.ts
```

### Plugin Manifest (`plugin.json`)

Declares all extension points declaratively. Extension points available:

| Section | What it adds |
|---------|-------------|
| `routes` | A new Angular route (full page) |
| `features.navbar` | Left-nav entry pointing at the route |
| `features.toolbar` | Button in the document-list or viewer toolbar |
| `features.contextMenu` | Right-click menu item |
| `features.sidebar.tabs` | New tab in the ACA info drawer |

`actions` define NgRx action type strings dispatched when the user clicks. `rules.visible`
controls conditional display using ADF rule evaluators (e.g. `app.selection.file`).

### Providers Function Pattern

```typescript
export function provide{ExtName}Extension(): (Provider | EnvironmentProviders)[] {
  return [
    provideExtensionConfig(['{ext-name}.plugin.json']),
    provideEffects({ExtName}Effects),
    {
      provide: APP_INITIALIZER,
      useFactory: register{ExtName}Components,
      deps: [ExtensionService],
      multi: true
    }
  ];
}
```

- Register components with `ExtensionService.setComponents()` inside the `APP_INITIALIZER` factory.
- The `APP_INITIALIZER` factory runs before routing resolves; registration must happen here.
- Expose a deprecated `@NgModule` shim for ADW compatibility.

### Service Pattern

```typescript
@Injectable({ providedIn: 'root' })
export class {ServiceName}Service {
  private baseUrl = this.appConfig.get<string>(
    'plugins.{extPrefix}Service.baseUrl', '/default-url'
  );
  constructor(private http: HttpClient, private appConfig: AppConfigService) {}
}
```

### Integration Patches (applied to the ACA/ADW source)

Three files in the host app must be patched after copying the extension folder:

1. `app/src/app/extensions.module.ts` — import and spread `provide{ExtName}Extension()`
2. `app/project.json` — add `{ext-name}.plugin.json` to `build.options.assets`
3. `app/src/app.config.json` — add `plugins.{extPrefix}Service.baseUrl`

---

## Forbidden Patterns

These patterns must **never** appear in generated code. Actively check for and reject them.

| Pattern | Reason | Alternative |
|---------|--------|-------------|
| Declaring an ACA/ADW Angular component in `@NgModule` `imports` or `declarations` | ACA/ADW extension components must be `standalone: true` and registered with `ExtensionService.setComponents()` via `APP_INITIALIZER` — not through NgModule metadata | Use `standalone: true` and register via `extensions.setComponents()` |
| Hardcoding backend API URLs in Angular services or components | URLs differ between dev, staging, and production; hardcoded paths break proxy configuration | Read from `AppConfigService` using `plugins.{extPrefix}Service.baseUrl` |
| Generating a separate Angular `package.json` and `npm install` step for an ACA extension | ACA/ADW extensions are source drop-ins compiled as part of the host app — they share the host's `node_modules` | Copy the extension folder into `projects/` (ACA) or `libs/` (ADW Nx); no separate `package.json` |
| Direct Hibernate/JPA access | Bypasses Alfresco service layer and permissions | Use `NodeService`, `ContentService` |
| `AuthenticationUtil.runAsSystem` in user-facing code | Privilege escalation | Use `runAs(userName)` or proper permission checks |
| Hardcoded credentials | Security vulnerability | Environment variables or encrypted properties |
| Hardcoded `NodeRef` strings | Brittle, environment-specific | Query by path or property |
| Non-paged REST responses | Memory issues with large result sets | Always implement paging envelope |
| Bypassing `PermissionService` | Security vulnerability | Always check permissions |
| Direct JCR access | Deprecated and unsupported | Use Alfresco services |
| `System.out.println` | Not production logging | Use SLF4J `LoggerFactory` |
| Synchronous HTTP calls in behaviours | Transaction timeout risk | Use async events or actions |
| `@Transactional` on Alfresco service calls | Alfresco manages its own transactions | Use `RetryingTransactionHelper` if needed |
| Wildcard imports (`import *`) | Clarity and conflict risk | Explicit imports |
| Reserved namespace prefixes | Conflicts with Alfresco core | Use project-specific prefix |
| `<mandatory enforced="true">` on aspect properties | `enforced="true"` fires `IntegrityChecker` via `OnAddAspectPolicy` before `addAspect()` writes the properties map, causing a spurious `IntegrityException: Mandatory property not set` | Use `<mandatory>true</mandatory>` (no `enforced` attribute) — defers the check to `beforeCommit` |
| Lucene query language or `@variable` property syntax | `SearchService.LANGUAGE_LUCENE` and the `@{namespace}property` / `@prefix\:property` notation are deprecated since ACS 6.x, incompatible with Search Enterprise (Elasticsearch/OpenSearch), and produce unpredictable results with Solr 6+. Example of the forbidden pattern: `sp.setLanguage(LANGUAGE_LUCENE); sp.setQuery("@cm\\:name:\"foo\"")` | Always use `SearchService.LANGUAGE_FTS_ALFRESCO` with AFTS syntax: `sp.setLanguage(LANGUAGE_FTS_ALFRESCO); sp.setQuery("cm:name:\"foo\"")` |
| Quoted phrase syntax in transactional AFTS queries | `@prefix\:prop:"value"` triggers `DEFAULT` analysis mode, which the DB query engine rejects with `QueryModelException: Analysis mode not supported for DB DEFAULT` | Prefix with `=`: `=@prefix\:prop:"value"` to force `IDENTIFIER`/exact-match mode |
| Expensive operations before eligibility check in behaviours | Every upload pays the full behaviour cost even when the behaviour is not configured for that folder | Check scope/eligibility first (cheap `NodeService` calls); return early before any content streaming, hashing, or locking |
| `org.flowable.*` imports in workflow or task listener code | ACS 26.1 uses Activiti 5.22.x — Flowable API is not on the classpath | Use `org.activiti.engine.*` from Activiti 5.x only |
| `redeploy=true` on workflow definitions | Re-deploys on every ACS restart, creating duplicate process definition versions in the Activiti DB | Always set `<prop key="redeploy">false</prop>`; use the Workflow Console to manually undeploy before restarting |
| Synchronous external HTTP calls inside service tasks or task listeners | Runs inside the ACS transaction; timeouts cause transaction rollback and workflow state corruption | Use Alfresco Action Service to queue async work; or use a separate boundary event for external integration |
| Registering BPMN files via `dictionaryModelBootstrap` | `dictionaryModelBootstrap` does not know about Activiti's process engine — BPMN files are silently ignored | Use a separate `workflowDeployer` bean |
| Omitting `bpm` import from workflow model XML | Workflow task types extend `bpm:startTask` or `bpm:activitiOutcomeTask` — the import is mandatory | Always add `<import uri="http://www.alfresco.org/model/bpm/1.0" prefix="bpm"/>` |
| Using the legacy `RenditionDefinition` (Rendition Service 1) class for new renditions | Rendition Service 1 is deprecated in ACS 26.1; renditions defined with the old API may not fire through the out-of-process Transform Service | Use `org.alfresco.repo.rendition2.RenditionDefinition2Impl` with `registry` ref `renditionDefinitionRegistry2` |
| Registering MIME types via Spring beans | The mimetype service does not discover Spring beans; the MIME type will not be registered | Place a `mimetypes-extension-map.xml` file under `alfresco/extension/mimetype/` using Alfresco config XML format |
| Building a custom transform engine for a mimetype pair already in `alfresco-transform-core-aio` | Duplicates work, adds infrastructure complexity, and may conflict with the AIO container's routing | Verify coverage in ImageMagick, LibreOffice, PDFRenderer, and Tika before building a custom engine |
| Generating `Application.java` in a custom T-Engine project | `alfresco-base-t-engine` already provides `org.alfresco.transform.base.Application`; a second main class causes a startup conflict | Set `<mainClass>org.alfresco.transform.base.Application</mainClass>` in the `spring-boot-maven-plugin` and omit `Application.java` |
| Adding `localTransform.{name}.url` to ACS JAVA_OPTS for ACS 26.1 | That property is the ACS 25.x Community pattern (direct engine URL); ACS 26.1 routes transforms through `transform-router` | Register the engine with `transform-router` via `{ENGINE_UPPER}_URL` and `TRANSFORMER_QUEUE_{ENGINE_UPPER}` environment variables |
| Implementing `Patch` interface directly in a custom patch | The interface has no transaction management, no schema version checking, and no `alf_applied_patch` recording | Extend `AbstractPatch` — it handles all lifecycle, transaction, and recording automatically |
| Declaring `nodeService`, `searchService`, or `transactionService` as fields in a patch class | `basePatch` already injects these as `protected` fields on `AbstractPatch`; redeclaring them as new fields shadows the injected ones and causes `NullPointerException` | Use the inherited `protected` fields directly — do not re-declare or re-inject them |
| Not closing `ResultSet` in a patch | Open `ResultSet` objects hold database cursors; failing to close them causes resource exhaustion in long-running patches | Always close `ResultSet` in a `finally` block: `if (results != null) results.close()` |
| Using a patch to create initial data on a fresh install | Patches are designed for migration of existing data; on a fresh install `fixesFromSchema=0` patches do apply, but bootstrap loaders (`parent="module.baseComponent"`) are the correct pattern for initial data | Use `/bootstrap-loader` for first-install data; use `/repository-patch` for cross-version migration |
| Implementing `ActionConditionEvaluator` directly in a custom condition | The interface has no `init()` or `addParameterDefinitions()` support; the evaluator is never registered with the Action Service | Extend `ActionConditionEvaluatorAbstractBase` — the abstract base calls `init()` automatically when wired with `parent="action-condition-evaluator"` |
| Overriding `evaluate()` instead of `evaluateImpl()` in a condition evaluator | `evaluate()` is implemented by `ActionConditionEvaluatorAbstractBase` and must not be overridden — it handles pre/post logic and calls `evaluateImpl()` | Override `protected boolean evaluateImpl(ActionCondition, NodeRef)` only |
| Using `parent="action-executer"` for a condition evaluator bean | `action-executer` registers the bean as an action, not a condition; the evaluator will not appear in the rule condition list | Use `parent="action-condition-evaluator"` |
| `@PostConstruct` or `ApplicationReadyEvent` for repository data initialisation | Fires on every ACS restart, creating duplicate folders, categories, or nodes on each server start | Extend `AbstractModuleComponent` with `parent="module.baseComponent"` — the framework tracks execution in the DB and runs `executeInternal()` exactly once per `sinceVersion` |
| Extending `AbstractLifecycleBean` for a data bootstrap loader | `AbstractLifecycleBean` does not integrate with the module component tracking system; provides no idempotency guarantee | Extend `AbstractModuleComponent` instead |
| Hardcoding a `NodeRef` string for Company Home or other well-known locations in a bootstrap loader | NodeRef UUIDs differ between repositories; hardcoded refs break on any install other than the original | Use `nodeLocatorService.getNode("companyhome", null, null)` |
| `RetryingTransactionHelper` inside `executeInternal()` | `AbstractModuleComponent.executeInternal()` already runs inside a transaction managed by the module framework; wrapping again causes nested transaction issues | Use repository services directly within `executeInternal()` |
| `@Scheduled` in a Platform JAR | Spring's `@Scheduled` is not integrated with Quartz or `JobLockService`; fires on every cluster node simultaneously causing duplicate work and data corruption | Extend `AbstractScheduledLockedJob`, register via `CronTriggerBean` wired to `schedulerFactory` |
| `@Transactional` on a scheduled job executer method | Alfresco's transaction infrastructure is managed by `RetryingTransactionHelper`, not Spring's `@Transactional` proxy | Wrap repository calls in `retryingTransactionHelper.doInTransaction()` |
| Quartz `startDelay` below 240000 ms | ACS may not have fully initialised (dictionary, subsystems, indexes) when the job first fires, causing `NullPointerException` or `ServiceUnavailableException` | Always set `startDelay` to at least `240000` (4 minutes) on `CronTriggerBean` |
| Alfresco service references as fields on a Quartz `Job` class | Quartz re-instantiates the Job class for each execution; injected fields are lost | Keep the Job class stateless; inject services into the Executer bean instead |
| Two `AbstractModuleComponent` beans with the same `name` property in the same module | The framework keys execution records by `moduleId + name + sinceVersion`; duplicate names cause one loader to silently overwrite the other's execution record | Give each bootstrap loader a unique `name` value (e.g. `FoldersBootstrapLoader`, `CategoriesBootstrapLoader`) |
| Non-unique patch `id` property across modules | `alf_applied_patch.id` is a unique key; if two modules declare the same id, the second patch is silently skipped | Always prefix patch IDs with the module ID: `patch.{module-id}.{uniqueName}` |
| Missing `<repositories>` block in a custom Transform Engine `pom.xml` | `alfresco-transform-core` and `alfresco-base-t-engine` are on Alfresco Nexus, not Maven Central; the Docker build fails with `Non-resolvable parent POM` | Always include `<repository><id>alfresco-public</id><url>https://artifacts.alfresco.com/nexus/content/groups/public</url></repository>` in the engine `pom.xml` |
| Missing Apache 2.0 license header on Java source files in an Out-of-Process Spring Boot project | The `alfresco-java-sdk` parent POM runs `license-maven-plugin:check` during the validate phase; files without the header cause `BUILD FAILURE: Some files do not have the expected license header` | Add the Apache 2.0 license header block at the top of every generated `.java` file in Out-of-Process projects |
| Adding `solr6` or `elasticsearch` to the `alfresco` service's `depends_on` in compose.yaml | Creates a circular dependency: `alfresco → solr6 → alfresco`. Solr/OpenSearch discovers ACS after startup — ACS does not need to wait for them | The `alfresco` service depends only on `postgres`, `activemq`, and `transform-core-aio`. Solr/OpenSearch depend on `alfresco`. |
| Accessing Alfresco repository services directly inside a Spring Boot Out-of-Process event listener | The event listener runs in a separate JVM with no access to `NodeService`, `ContentService`, or other repository beans | Call the Alfresco REST API (e.g. `/alfresco/api/-default-/public/alfresco/versions/1/nodes/{nodeId}`) or delegate to a repository action via the Action REST API |
