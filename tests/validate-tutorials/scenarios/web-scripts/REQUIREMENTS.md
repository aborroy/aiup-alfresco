# Requirements: Web Scripts

## 1. Business Purpose
Expose a REST API for reading, posting, and deleting content ratings on ACS documents,
and a read-only API for listing whitepapers. Mirrors the web scripts from the
alfresco-developer-series webscripts tutorial.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: web-scripts
- **Platform module**: web-scripts-platform
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an API consumer, I can GET a rating for a document by node ID.
- As an API consumer, I can POST a new rating for a document.
- As an API consumer, I can DELETE a rating by node ID.
- As an API consumer, I can GET a list of whitepaper documents.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:doc` extends `cm:content`
  - `sc:isActive` (d:boolean, optional)
- `sc:whitepaper` extends `sc:doc`

### Aspects
- `sc:rateable`
  - `sc:totalRating` (d:int, optional)
  - `sc:ratingCount` (d:int, optional)
  - `sc:averageRating` (d:float, optional)

## 6. API Requirements
- `GET /api/sc/ratings?id={nodeId}` — returns rating data for the node; auth: user;
  format: json; transaction: required; cache: never.
- `POST /api/sc/ratings?id={nodeId}` — adds a new rating; auth: user; format: json;
  transaction: required; cache: never.
- `DELETE /api/sc/ratings?id={nodeId}` — removes a rating node; auth: user; format: json;
  transaction: required; cache: never.
- `GET /api/sc/whitepapers` — lists active whitepapers; auth: user; format: json;
  transaction: required; cache: never.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Platform JAR with Web Script beans registered in webscript-context.xml.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | ratings.get.desc.xml, ratings.get.json.ftl | |
| US-02 | ratings.post.desc.xml, ratings.post.json.ftl | |
| US-03 | ratings.delete.desc.xml | |
| US-04 | whitepapers.get.desc.xml, whitepapers.get.json.ftl | |
