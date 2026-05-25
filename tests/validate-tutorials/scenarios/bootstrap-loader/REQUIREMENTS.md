# Requirements: Bootstrap Loader

## 1. Business Purpose
On first deployment, create a standard folder hierarchy under Company Home for the SomeCo
document management extension: an "Archive" folder and a "Templates" folder. These folders
must be created exactly once and never duplicated on subsequent restarts.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: bootstrap-loader
- **Platform module**: bootstrap-loader
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an administrator, when the extension is first deployed, an "Archive" folder and a
  "Templates" folder are automatically created under Company Home.
- As an administrator, restarting ACS does not create duplicate folders.
- As a developer, I can re-run the bootstrap by incrementing sinceVersion without touching
  the database.

## 5. Content Model Requirements
None beyond standard cm:folder.

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Bootstrap loader requirements
- **Loader name**: `SomeCoFolders`
- **sinceVersion**: `1.0`
- **Creates**: `Archive` folder and `Templates` folder under Company Home
- Use `nodeLocatorService` to locate Company Home
- Use `FileFolderService` to create folders
- Use `findOrCreateFolder` pattern for idempotency within the component
- Must extend `AbstractModuleComponent` with `parent="module.baseComponent"`
- Must **not** use `@PostConstruct`, `RetryingTransactionHelper`, or `@Transactional`

## 8. Deployment Requirements
- Platform JAR with bootstrap loader bean registered in `bootstrap-context.xml`.
- `bootstrap-context.xml` imported from `module-context.xml`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | SomeCoFoldersBootstrapLoader.java, bootstrap-context.xml | SomeCoFoldersBootstrapLoaderTest.java |
| US-02 | SomeCoFoldersBootstrapLoader.java (findOrCreateFolder) | SomeCoFoldersBootstrapLoaderTest.java |
| US-03 | bootstrap-context.xml (sinceVersion) | |
