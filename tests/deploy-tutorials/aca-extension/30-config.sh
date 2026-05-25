#!/usr/bin/env sh
# Inject APP_CONFIG_ECM_HOST into app.config.json at container startup.
set -e
CONFIG="/usr/share/nginx/html/app.config.json"
if [ -f "$CONFIG" ] && [ -n "${APP_CONFIG_ECM_HOST:-}" ]; then
    # Replace the ecmHost value in app.config.json
    sed -i "s|\"ecmHost\": \"[^\"]*\"|\"ecmHost\": \"${APP_CONFIG_ECM_HOST}\"|g" "$CONFIG" || true
fi
