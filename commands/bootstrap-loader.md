---
description: "Generate an AbstractModuleComponent data bootstrap loader that creates initial folders, categories, or reference data exactly once per module version. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /bootstrap-loader — Bootstrap Data Loader Generator

> **In-Process SDK only** — bootstrap loaders deploy inside the ACS JVM as part of the Platform JAR.
> Never use `@PostConstruct` or `ApplicationReadyEvent` for repository data initialisation — they
> fire on every server restart and will create duplicate data.

Generate an Alfresco module component that initialises folders, categories, or reference data
exactly once per module version per repository.

## Input

Read `REQUIREMENTS.md` to identify bootstrap loader requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that `/bootstrap-loader`
     only applies to the in-process Platform JAR project.

2. Read Section 7 (Behaviour Requirements) sub-section "Bootstrap loader requirements".
   - If no bootstrap loader requirements are present in Section 7, stop and ask the user to run
     `/requirements` first (or provide a description as `$ARGUMENTS`).

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `my-extension`).
     Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from
     Section 2. **Never use the full `module.id` property value as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)
   - `{groupId}` — the Maven groupId declared in Section 2

4. Derive from bootstrap loader requirements:
   - `{LoaderName}` — PascalCase loader name (e.g. `ArchiveFolders`, `CategoryReference`)
   - `{sinceVersion}` — the module version from which this loader applies (e.g. `1.0`)
   - What data to create: folders (with paths under Company Home), categories, or reference nodes

---

## Output Files

> **All three artefacts below are required and must be generated together in a single run:**
> the loader class, the bootstrap context XML entry, and the unit test.

### 1. Bootstrap Loader Class
`{platform-project-root}/src/main/java/{package}/bootstrap/{LoaderName}BootstrapLoader.java`

```java
package {package}.bootstrap;

import org.alfresco.repo.module.AbstractModuleComponent;
import org.alfresco.repo.nodelocator.NodeLocatorService;
import org.alfresco.service.cmr.repository.ChildAssociationRef;
import org.alfresco.service.cmr.repository.NodeRef;
import org.alfresco.service.cmr.repository.NodeService;
import org.alfresco.service.cmr.model.FileFolderService;
import org.alfresco.service.cmr.model.FileInfo;
import org.alfresco.service.namespace.NamespaceService;
import org.alfresco.service.namespace.QName;
import org.alfresco.model.ContentModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.List;

public class {LoaderName}BootstrapLoader extends AbstractModuleComponent {

    private static final Logger LOG = LoggerFactory.getLogger({LoaderName}BootstrapLoader.class);

    private NodeService nodeService;
    private FileFolderService fileFolderService;
    private NodeLocatorService nodeLocatorService;

    @Override
    protected void executeInternal() throws Throwable {
        LOG.info("{LoaderName}BootstrapLoader: starting");

        NodeRef companyHome = nodeLocatorService.getNode("companyhome", null, null);
        if (companyHome == null) {
            throw new IllegalStateException("Company Home not found — cannot bootstrap data");
        }

        // Create required folder structure
        // {loader-specific logic derived from requirements}

        LOG.info("{LoaderName}BootstrapLoader: completed");
    }

    /** Find a child folder by name; returns null if not found. */
    protected NodeRef findFolder(NodeRef parent, String name) {
        List<ChildAssociationRef> children = nodeService.getChildAssocs(parent);
        for (ChildAssociationRef ref : children) {
            String childName = (String) nodeService.getProperty(ref.getChildRef(), ContentModel.PROP_NAME);
            if (name.equals(childName) && ContentModel.TYPE_FOLDER.equals(nodeService.getType(ref.getChildRef()))) {
                return ref.getChildRef();
            }
        }
        return null;
    }

    /** Find or create a folder by name under parent. */
    protected NodeRef findOrCreateFolder(NodeRef parent, String name) {
        NodeRef existing = findFolder(parent, name);
        if (existing != null) {
            LOG.debug("Folder '{}' already exists — skipping creation", name);
            return existing;
        }
        FileInfo info = fileFolderService.create(parent, name, ContentModel.TYPE_FOLDER);
        LOG.debug("Created folder '{}'", name);
        return info.getNodeRef();
    }

    public void setNodeService(NodeService nodeService) {
        this.nodeService = nodeService;
    }

    public void setFileFolderService(FileFolderService fileFolderService) {
        this.fileFolderService = fileFolderService;
    }

    public void setNodeLocatorService(NodeLocatorService nodeLocatorService) {
        this.nodeLocatorService = nodeLocatorService;
    }
}
```

Key rules for the Java class:
- Always extend `AbstractModuleComponent` — never implement `ModuleComponent` directly, never extend `AbstractLifecycleBean`.
- Override `protected void executeInternal() throws Throwable` — this is the only lifecycle method to override.
- Do **not** add `@Transactional` — the module framework already provides a transaction.
- Do **not** wrap calls in `RetryingTransactionHelper.doInTransaction()` — already transactional.
- Use `AuthenticationUtil.runAsSystem()` only if the specific operation requires system-level access beyond the module context; do not use it by default.
- Use setter injection only — no `@Autowired`.
- Always call `nodeLocatorService.getNode("companyhome", null, null)` to obtain Company Home — never hardcode a `NodeRef` string.
- Use `findOrCreateFolder()` helpers (or equivalent) for all node creation to make the loader safe to re-run in development (e.g. after wiping and re-starting with the same version).

### 2. Bootstrap Context Entry
Add to `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/bootstrap-context.xml`:

```xml
<!-- {LoaderName} bootstrap loader — runs once per module version (tracked in DB) -->
<bean id="{groupId}.{LoaderName}BootstrapLoader"
      class="{package}.bootstrap.{LoaderName}BootstrapLoader"
      parent="module.baseComponent">
    <property name="moduleId"           value="{module-id}"/>
    <property name="name"               value="{LoaderName}BootstrapLoader"/>
    <property name="description"        value="Bootstrap initial data for {module-id}"/>
    <property name="sinceVersion"       value="{sinceVersion}"/>
    <property name="appliesFromVersion" value="0.99"/>
    <property name="nodeService"        ref="NodeService"/>
    <property name="fileFolderService"  ref="FileFolderService"/>
    <property name="nodeLocatorService" ref="nodeLocatorService"/>
</bean>
```

If `bootstrap-context.xml` already exists (created by `/content-model`): append the bean to the
existing file. Do **not** create a second `bootstrap-context.xml`.

If `bootstrap-context.xml` does not yet exist, create it and also add the import to
`module-context.xml`:
```xml
<import resource="classpath:alfresco/module/{module-id}/context/bootstrap-context.xml"/>
```

### 3. Unit Test
`{platform-project-root}/src/test/java/{package}/bootstrap/{LoaderName}BootstrapLoaderTest.java`

```java
package {package}.bootstrap;

import org.alfresco.repo.nodelocator.NodeLocatorService;
import org.alfresco.service.cmr.model.FileFolderService;
import org.alfresco.service.cmr.model.FileInfo;
import org.alfresco.service.cmr.repository.ChildAssociationRef;
import org.alfresco.service.cmr.repository.NodeRef;
import org.alfresco.service.cmr.repository.NodeService;
import org.alfresco.service.cmr.repository.StoreRef;
import org.alfresco.model.ContentModel;
import org.alfresco.service.namespace.QName;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class {LoaderName}BootstrapLoaderTest {

    @Mock NodeService nodeService;
    @Mock FileFolderService fileFolderService;
    @Mock NodeLocatorService nodeLocatorService;
    @Mock FileInfo fileInfo;

    private {LoaderName}BootstrapLoader loader;
    private final NodeRef companyHome = new NodeRef(StoreRef.STORE_REF_WORKSPACE_SPACESSTORE, "company-home-id");
    private final NodeRef newFolder   = new NodeRef(StoreRef.STORE_REF_WORKSPACE_SPACESSTORE, "new-folder-id");

    @BeforeEach
    void setUp() {
        loader = new {LoaderName}BootstrapLoader();
        loader.setNodeService(nodeService);
        loader.setFileFolderService(fileFolderService);
        loader.setNodeLocatorService(nodeLocatorService);
    }

    @Test
    void executeInternal_createsFolder_whenNotExists() throws Throwable {
        when(nodeLocatorService.getNode("companyhome", null, null)).thenReturn(companyHome);
        when(nodeService.getChildAssocs(companyHome)).thenReturn(Collections.emptyList());
        when(fileFolderService.create(eq(companyHome), any(), eq(ContentModel.TYPE_FOLDER)))
            .thenReturn(fileInfo);
        when(fileInfo.getNodeRef()).thenReturn(newFolder);

        loader.executeInternal();

        verify(fileFolderService).create(eq(companyHome), any(), eq(ContentModel.TYPE_FOLDER));
    }

    @Test
    void executeInternal_skipsFolder_whenAlreadyExists() throws Throwable {
        when(nodeLocatorService.getNode("companyhome", null, null)).thenReturn(companyHome);

        ChildAssociationRef existingRef = new ChildAssociationRef(
            ContentModel.ASSOC_CONTAINS, companyHome, QName.createQName("{test}folder"),
            newFolder, true, -1);
        when(nodeService.getChildAssocs(companyHome)).thenReturn(Collections.singletonList(existingRef));
        when(nodeService.getProperty(newFolder, ContentModel.PROP_NAME)).thenReturn("Archive");
        when(nodeService.getType(newFolder)).thenReturn(ContentModel.TYPE_FOLDER);

        loader.executeInternal();

        verify(fileFolderService, never()).create(any(), any(), any());
    }
}
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Derive it as
  `{platform-artifactId}` from Section 2 or from `<artifactId>` in the platform `pom.xml`.
  **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Loader class naming: `{LoaderName}BootstrapLoader.java`
- Bean ID: `{groupId}.{LoaderName}BootstrapLoader` (uses groupId to ensure global uniqueness)
- `moduleId` property value must exactly match the `module.id` from `module.properties`
- `sinceVersion` must match the module version in `module.properties`; use `0.99` for `appliesFromVersion`
  so it also applies to `1.0-SNAPSHOT` builds
- The framework records execution in the ACS database keyed by `moduleId + name + sinceVersion`;
  to re-run, increment `sinceVersion` — do **not** delete database records manually
- Always verify Company Home is non-null before proceeding
- Include `findOrCreateFolder` helpers (or equivalent) so the loader tolerates being re-run in
  development environments where the DB was reset without wiping the content store
- Never generate bootstrap loader classes inside the Event Handler project
