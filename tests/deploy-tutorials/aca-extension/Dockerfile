# syntax=docker/dockerfile:1.4
# Multi-stage build: clones ACA, patches with the ext-deploy-test extension, builds Angular,
# and serves the static output with nginx.
#
# Build args:
#   ACA_TAG — ACA branch or tag to build from (default: develop)
#
# Runtime env:
#   APP_CONFIG_ECM_HOST — ACS base URL injected at startup (default: http://localhost:8080)

FROM node:24-alpine AS builder

ARG ACA_TAG=develop

RUN apk add --no-cache git

WORKDIR /build

# Clone Alfresco Content App
RUN git clone --depth 1 --branch ${ACA_TAG} \
    https://github.com/Alfresco/alfresco-content-app.git .

# Copy the generated extension into the ACA projects directory
COPY generated/aca-extension/ext-deploy-test/  projects/ext-deploy-test/

# Patch 1: Register the extension in extensions.module.ts
RUN sed -i \
    "/provideAboutExtension\|provideApplicationExtensions/{ \
        s|provideAboutExtension()|provideAboutExtension()\n    ...provideDeployTestExtension(),|; \
    }" app/src/app/extensions.module.ts 2>/dev/null || true && \
    # Add import at top of extensions.module.ts
    sed -i \
    "1s|^|import { provideDeployTestExtension } from 'projects/ext-deploy-test/src/public-api';\n|" \
    app/src/app/extensions.module.ts

# Patch 2: Add plugin JSON to build assets (node-based for reliability)
RUN node -e " \
  const fs = require('fs'); \
  const pj = JSON.parse(fs.readFileSync('app/project.json', 'utf8')); \
  const assets = pj.targets.build.options.assets; \
  if (!assets.some(a => typeof a === 'object' && a.glob === 'ext-deploy-test.plugin.json')) { \
    assets.push({ \
      glob: 'ext-deploy-test.plugin.json', \
      input: 'projects/ext-deploy-test/src/assets', \
      output: './assets/plugins' \
    }); \
    fs.writeFileSync('app/project.json', JSON.stringify(pj, null, 2)); \
    console.log('Patched project.json'); \
  } \
"

# Patch 3: Increase bundle size budget
RUN sed -i 's/"maximumError": "5mb"/"maximumError": "6mb"/g' app/project.json 2>/dev/null || true

# Install and build
RUN npm ci
RUN npx nx build content-ce --configuration=production

# ---- Stage 2: nginx ----
FROM nginxinc/nginx-unprivileged:1.25-alpine

COPY aca-extension/nginx.conf /etc/nginx/conf.d/default.conf
COPY aca-extension/30-config.sh /docker-entrypoint.d/30-config.sh

USER root
RUN chmod +x /docker-entrypoint.d/30-config.sh && chmod a+w -R /etc/nginx/conf.d
USER 101

COPY --from=builder /build/dist/content-ce /usr/share/nginx/html/

ENV APP_CONFIG_ECM_HOST=http://localhost:8080

EXPOSE 8080
