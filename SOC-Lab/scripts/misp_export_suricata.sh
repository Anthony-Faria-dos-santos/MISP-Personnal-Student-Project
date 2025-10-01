#!/usr/bin/env bash
set -euo pipefail
MISP_URL="https://localhost:${MISP_HTTPS_PORT:-8443}"
MISP_KEY="${MISP_API_KEY:-<A_METTRE>}"
OUT="docker/configs/suricata/rules/misp.rules"

mkdir -p "$(dirname "$OUT")"

curl -sk -H "Authorization: $MISP_KEY" \
  "$MISP_URL/attributes/nids/suricata/download" > "$OUT"

echo "[OK] Règles MISP exportées vers $OUT"
