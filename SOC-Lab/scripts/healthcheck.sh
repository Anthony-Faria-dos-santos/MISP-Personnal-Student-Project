#!/usr/bin/env bash
set -euo pipefail
printf "\n[MISP] "; curl -skI https://localhost:${MISP_HTTPS_PORT:-8443} | head -n1 || true
printf "[Elasticsearch] "; curl -s http://localhost:${ELASTIC_PORT:-9200} | jq -r .version.number || true
printf "[Kibana] "; curl -s http://localhost:${KIBANA_PORT:-5601}/api/status | jq -r .version.number || true
