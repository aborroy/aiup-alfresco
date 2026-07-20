# Requirements: Actions

## 1. Business Purpose
Provide custom Alfresco actions that allow rules and scripts to enable or disable the
sc:webable web-publication flag on documents, and to move a node when a newer version
replaces it. Mirrors the actions from the alfresco-developer-series actions tutorial.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: actions
- **Platform module**: actions-platform
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As a rule author, I can apply the "Enable Web" action to set sc:isActive=true on a document.
- As a rule author, I can apply the "Disable Web" action to set sc:isActive=false on a document.
- As a rule author, I can apply the "Set Web Flag" action with a boolean parameter to set sc:isActive.
- As a content manager, I can apply the "Move Replaced" action to move a superseded document.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:doc` extends `cm:content`
  - `sc:isActive` (d:boolean, optional)

### Aspects
- `sc:webable`
  - `sc:published` (d:boolean, mandatory)
  - `sc:publishedTime` (d:datetime, optional)

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Actions
- `EnableWebFlag` (`sc.enableWebFlag`): sets `sc:isActive=true` on the actioned node.
- `DisableWebFlag` (`sc.disableWebFlag`): sets `sc:isActive=false` on the actioned node.
- `SetWebFlag` (`sc.setWebFlag`): parameter `active` (d:boolean), sets `sc:isActive` accordingly.
- `MoveReplacedActionExecuter` (`sc.moveReplaced`): parameter `destination-folder` (d:noderef),
  moves the actioned node to the specified folder.

## 8. Deployment Requirements
- Platform JAR with action beans registered in service-context.xml.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | EnableWebFlag.java, service-context.xml | |
| US-02 | DisableWebFlag.java, service-context.xml | |
| US-03 | SetWebFlag.java, service-context.xml | |
| US-04 | MoveReplacedActionExecuter.java, service-context.xml | |
