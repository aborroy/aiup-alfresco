# Requirements: Transforms

## 1. Business Purpose
Register two custom renditions for SomeCo documents:
1. A 200×200 JPEG thumbnail named `scThumbnail` — uses the built-in ImageMagick transform
   (no custom engine needed).
2. A Markdown rendition named `scMarkdown` that converts PDFs to `text/markdown` — this
   source→target pair is not covered by the AIO container, so a custom engine project is
   also required.

Additionally, register the `text/markdown` MIME type since ACS does not know it by default.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process) + Custom Transform Engine (out-of-process)
- **groupId**: com.someco
- **artifactId**: transforms (Platform JAR)
- **Platform module**: transforms
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As a user, previewing a SomeCo document shows a 200×200 JPEG thumbnail.
- As a user, I can request a Markdown rendition of a PDF document.
- As an administrator, the custom Markdown engine runs as a separate container.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:doc` extends `cm:content`

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Transform and rendition requirements

**Rendition 1 — `scThumbnail`**
- Source: any image (built-in ImageMagick covers this)
- Target: `image/jpeg`
- Options: resizeWidth=200, resizeHeight=200, maintainAspectRatio=true, thumbnail=true
- No custom engine needed

**Rendition 2 — `scMarkdown`**
- Source: `application/pdf`
- Target: `text/markdown`
- Options: timeout only
- Custom engine required (pair not in AIO)
- Engine name: `markdownEngine`

**MIME type registration**
- `text/markdown` with extension `md` must be registered via `mimetypes-extension-map.xml`

## 8. Deployment Requirements
- Platform JAR with rendition beans in `rendition-context.xml`
- Custom engine as a separate Spring Boot project `sc-markdown-engine/` with Dockerfile
- Custom engine service added to `compose.yaml`

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | rendition-context.xml (scThumbnail bean) | |
| US-02 | rendition-context.xml (scMarkdown bean), sc-markdown-engine/ | |
| US-03 | sc-markdown-engine/Dockerfile, compose.yaml snippet | |
