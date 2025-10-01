#!/usr/bin/env bash
set -euo pipefail
mkdir -p seed/misp-events

IN=seed/feeds/openphish.txt
OUT=seed/misp-events/openphish-batch.json

if [ ! -f "$IN" ]; then
  echo "Le fichier $IN est introuvable. Lance d'abord: bash scripts/fetch_feeds.sh"
  exit 1
fi

echo '{ "Event": { "info": "OpenPhish batch", "threat_level_id": 3, "analysis": 0, "distribution": 0, "Attribute": [' > "$OUT"
first=true
while IFS= read -r url; do
  url=$(echo "$url" | tr -d '\r\n')
  [ -z "$url" ] && continue
  if [ "$first" = true ]; then first=false; else echo "," >> "$OUT"; fi
  printf '{"type":"url","category":"Network activity","to_ids":true,"value":"%s"}' "$url" >> "$OUT"
done < "$IN"
echo '] } }' >> "$OUT"

echo "[OK] JSON MISP généré: $OUT"
