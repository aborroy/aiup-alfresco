# Requirements: ACA Extension Deploy Test

## 1. Business Purpose
Validate that an ACA/ADW UI extension can be built into a custom ACA Docker image
(by cloning ACA, applying the extension, and running the Angular build) and that the
resulting nginx-served app returns HTTP 200 on the root URL.

## 2. Project Architecture
- **Extension type**: ACA/ADW UI extension (source drop-in, Angular)
- **Extension name**: ext-deploy-test
- **Vendor**: SomeCo
- **Backend base URL**: `/alfresco/api/-default-/public/alfresco/versions/1` (standard Alfresco REST only)
- **Extension points**: page (full-page only — minimal for fast build validation)
- **ACS version**: 26.1

## 3. Target Environment
- Node.js 24 (as used by ACA 7.x+)
- Docker multi-stage build
- Docker Compose v2

## 4. User Stories
- As a CI pipeline, the ACA Docker image builds successfully with the extension patched in.
- As a CI pipeline, the deployed ACA container serves HTTP 200 on its root URL.

## 5. Content Model Requirements
None.

## 6. API Requirements
None — extension uses standard Alfresco REST API only.

## 7. Behaviour Requirements
### ACA/ADW extension requirements
- **Extension name**: `ext-deploy-test`
- **Vendor**: SomeCo
- **Extension points**: page only (navbar entry + route — no sidebar, toolbar, contextMenu)
- **Page component**: `DeployTestPageComponent`
- **Service**: `DeployTestService` (calls standard Alfresco nodes API)
- No custom HTTP interceptor needed (standard ADF auth handles it)

## 8. Deployment Requirements
- Dockerfile: multi-stage build cloning ACA, patching with ext-deploy-test, building
- nginx serves the built app on port 8080
- Compose: single `content-app` service (no ACS needed for build validation)
- Runtime env: `APP_CONFIG_ECM_HOST=http://localhost:8080` (placeholder, not connected to real ACS)

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | Dockerfile | Docker build exits 0 |
| US-02 | compose.yaml (content-app service) | GET http://localhost:4200 returns HTTP 200 |
