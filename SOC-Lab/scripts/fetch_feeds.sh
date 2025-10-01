#!/usr/bin/env bash
set -euo pipefail
mkdir -p seed/feeds

# OpenPhish community (URLs, 1 par ligne)
curl -s https://openphish.com/feed.txt -o seed/feeds/openphish.txt || true

# URLhaus recent CSV
curl -s https://urlhaus.abuse.ch/downloads/csv_recent/ -o seed/feeds/urlhaus_recent.csv || true

echo "[OK] Feeds téléchargés -> seed/feeds/ (OpenPhish, URLhaus)"
