#!/usr/bin/env bash
set -euo pipefail
MISP_URL="https://localhost:${MISP_HTTPS_PORT:-8443}"
MISP_KEY="${MISP_API_KEY:-<A_METTRE>}"

read -r -d '' PAYLOAD <<'JSON'
{
  "info": "Phishing Banque – Sept. 2025",
  "threat_level_id": 3,
  "analysis": 0,
  "distribution": 0,
  "Attribute": [
    {"type":"domain","category":"Network activity","to_ids":true,"value":"login-secure-banque.fr"},
    {"type":"url","category":"Network activity","to_ids":true,"value":"http://login-secure-banque.fr/auth"},
    {"type":"ip-dst","category":"Network activity","to_ids":true,"value":"203.0.113.42"}
  ],
  "Tag":[{"name":"tlp:green"},{"name":"misp-galaxy:attack-pattern=Phishing (T1566)"}]
}
JSON

curl -sk -H "Authorization: $MISP_KEY" -H "Content-Type: application/json" \
  -X POST "$MISP_URL/events" -d "$PAYLOAD" | jq .
