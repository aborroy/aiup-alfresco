# Requirements: Share Form Configuration

## 1. Business Purpose
Customize the legacy Share UI forms for a custom document type so that its properties appear in
the create/edit/view forms and the document-library metadata panel, with grouped field layout
and localized labels.

## 2. Project Architecture
- **Extension type**: Share JAR
- **groupId**: com.someco
- **artifactId**: share-config
- **Share module**: share-config
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community, Share 26.1
- Java 17
- Maven 3.9+

## 4. User Stories
- As a content manager, when I edit a `sc:doc` in Share I see the `sc:isActive` and
  `sc:campaign` fields grouped under a "General" panel.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types (reused from the repository model)
- `sc:doc` extends `cm:content`
  - `sc:isActive` (d:boolean)
  - `sc:campaign` (d:text)

## 6. API Requirements
None.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Share JAR with `share-config-custom.xml` under `META-INF/`.
- A Share message bundle providing the `label-id` keys.
- No Share files written under `alfresco/module/...`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | share-config-custom.xml, {module-id}-share.properties | (structure validation) |
