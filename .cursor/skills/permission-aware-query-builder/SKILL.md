---
name: permission-aware-query-builder
description: Warns when CMIS or Alfresco Query Language queries may bypass ACLs. Suggests SearchService with authority context instead. Trigger when generating search or query code.
---


# Permission-Aware Query Builder

Review generated query code for potential ACL bypass issues.

## Rules

1. **Never use direct JDBC/Hibernate queries** to access nodes — these bypass the permission model entirely
2. **CMIS queries** run in the context of the authenticated user by default — this is safe
3. **SearchService queries** — verify `SearchParameters` includes authority context when needed
4. **`AuthenticationUtil.runAsSystem`** — flag any query executed inside `runAsSystem` as a potential security issue unless explicitly justified
5. **`sys_acl` / `sys_racl`** — when using Search Enterprise (Elasticsearch), verify that ACL fields are included in the search index configuration
6. **Solr AFTS queries** — respect `fts.alfresco.defaultNamespace` setting; warn if queries hardcode node refs

## Output
Flag each potential ACL bypass with severity (high/medium/low), explanation, and suggested fix.
