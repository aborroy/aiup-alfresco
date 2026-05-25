# Requirements: Content Types

## 1. Business Purpose
Define a custom content model for SomeCo that introduces a base document type, a whitepaper
type, a webable aspect (web-publication flags), and a rateable aspect (rating aggregates).
Mirrors the SomeCo model from the alfresco-developer-series content tutorial.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: content-types
- **Platform module**: content-types-platform
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As a content manager, I can create documents of type sc:doc with standard metadata.
- As a content manager, I can create whitepapers of type sc:whitepaper with campaign info.
- As a publisher, I can apply the sc:webable aspect to flag a document for web publication.
- As a ratings administrator, I can apply the sc:rateable aspect to track rating aggregates.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:doc` extends `cm:content`
  - `sc:isActive` (d:boolean, optional)
  - `sc:campaign` (d:text, optional, LIST constraint: Application Syndication | Private Event Retailing | Social Shopping)
  - Association: `sc:relatedDocuments` (peer association, target `sc:doc`, many-to-many)
- `sc:whitepaper` extends `sc:doc`
  - No additional properties beyond inheritance

### Aspects
- `sc:webable`
  - `sc:published` (d:boolean, mandatory)
  - `sc:publishedTime` (d:datetime, optional)
- `sc:rateable`
  - `sc:totalRating` (d:int, optional)
  - `sc:ratingCount` (d:int, optional)
  - `sc:averageRating` (d:float, optional)

### Constraints
- `sc:campaignList`: LIST — Application Syndication, Private Event Retailing, Social Shopping

## 6. API Requirements
None.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Platform JAR with content model bootstrapped via dictionaryModelBootstrap bean.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | content-model.xml, SomeCoModel.java | content-model-validator |
| US-02 | content-model.xml | content-model-validator |
| US-03 | content-model.xml | content-model-validator |
| US-04 | content-model.xml | content-model-validator |
