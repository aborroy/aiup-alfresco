# Requirements: Behaviours

## 1. Business Purpose
Automatically maintain rating aggregates on a rateable document whenever a child rating
node is created or deleted. Mirrors the Rating behaviour from the alfresco-developer-series
behaviors tutorial.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: behaviours
- **Platform module**: behaviours-platform
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As a user, when I add a rating child node to a rateable document, the aggregate
  properties (totalRating, ratingCount, averageRating) on the parent are updated.
- As a user, when I delete a rating child node from a rateable document, the aggregate
  properties on the parent are recalculated.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/ratings/1.0`
- **Prefix**: `scr`

### Types
- `scr:rating` extends `cm:content`
  - `scr:rating` (d:int, mandatory)
  - `scr:rater` (d:text, optional)

### Aspects
- `scr:rateable`
  - `scr:totalRating` (d:int, optional)
  - `scr:ratingCount` (d:int, optional)
  - `scr:averageRating` (d:float, optional)

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Behaviours
- `RatingBehaviour`: binds to `NodeServicePolicies.OnCreateNodePolicy` and
  `NodeServicePolicies.OnDeleteNodePolicy` on type `scr:rating`.
  - On create: reads `scr:rating` property from new node, adds to parent's `scr:totalRating`,
    increments `scr:ratingCount`, recalculates `scr:averageRating`.
  - On delete: subtracts rating value from parent aggregates.
  - Notification frequency: `TRANSACTION_COMMIT`.
  - Uses `NodeService` to read/write properties; does not use `SearchService`.

## 8. Deployment Requirements
- Platform JAR with behaviour bean registered in service-context.xml.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | RatingBehaviour.java, service-context.xml | |
| US-02 | RatingBehaviour.java | |
