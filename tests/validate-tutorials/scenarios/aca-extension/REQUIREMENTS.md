# Requirements: ACA Extension

## 1. Business Purpose
Add a "Contract Review" panel to Alfresco Content Application (ACA) that allows users
to trigger an AI-powered contract review for any selected document. The extension adds
a context menu item, a toolbar button, a full-page review results view, and a sidebar tab
showing the review status of the selected document. A backend service at `/api/contracts`
provides the review and status APIs.

## 2. Project Architecture
- **Extension type**: ACA/ADW UI extension (source drop-in, Angular)
- **Extension name**: `ext-contract-review`
- **Vendor**: SomeCo
- **Backend base URL**: `/api/contracts`
- **ACS version**: 26.1 (ACA connects to it)

## 3. Target Environment
- Alfresco Content Application (ACA) source checkout
- Angular 19, ADF 8.4.x
- Node.js 18+

## 4. User Stories
- As a user, I can right-click any document and choose "Review Contract" to open the
  full-page review panel pre-scoped to that document.
- As a user, I can see a "Contract Review" toolbar button when a document is selected.
- As a user, I can navigate to the Contract Review page from the left navigation.
- As a user, I can see the review status of the selected document in a sidebar tab.

## 5. Content Model Requirements
None — the extension reads document metadata via the standard Alfresco REST API.

## 6. API Requirements
None defined in ACS — the backend service at `/api/contracts` is external.

## 7. Behaviour Requirements
### ACA/ADW extension requirements
- **Extension points**: page (full-page), sidebar, contextMenu, toolbar
- **Extension name**: `ext-contract-review`
- **Vendor**: SomeCo
- **Backend config key**: `plugins.extContractReviewService.baseUrl` = `/api/contracts`
- **Page component**: `ContractReviewPageComponent` — full review results view
- **Sidebar component**: `ContractReviewSidebarComponent` — status for selected node
- **Service**: `ContractReviewService` — calls `/api/contracts` endpoints
- **NgRx actions**: `EXT_CONTRACT_REVIEW_OPEN_PAGE`, `EXT_CONTRACT_REVIEW_ACTION_ON_FILE`
- All components must be `standalone: true`
- URLs read via `AppConfigService` — never hardcoded
- Must export `provideExtContractReviewExtension()` from `public-api.ts`

## 8. Deployment Requirements
- Extension folder placed under `projects/ext-contract-review/` in the ACA checkout
- Three integration patches applied to ACA source:
  1. `extensions.module.ts` — spread `provideExtContractReviewExtension()`
  2. `project.json` — add plugin JSON to build assets
  3. `app.config.json` — add `plugins.extContractReviewService.baseUrl`

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | ext-contract-review.plugin.json (contextMenu), ContractReviewPageComponent | |
| US-02 | ext-contract-review.plugin.json (toolbar), ContractReviewPageComponent | |
| US-03 | ext-contract-review.plugin.json (navbar, routes), ContractReviewPageComponent | |
| US-04 | ext-contract-review.plugin.json (sidebar), ContractReviewSidebarComponent | |
