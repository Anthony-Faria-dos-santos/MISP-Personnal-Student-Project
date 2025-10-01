# Feeds Phishing (OpenPhish / URLhaus) – Guide labo

## Sources
- OpenPhish (community feed): https://openphish.com/feed.txt
- URLhaus (recent CSV): https://urlhaus.abuse.ch/downloads/csv_recent/

> Utilisation strictement défensive et en environnement isolé. Respecter les CGU des fournisseurs.

## Usage rapide
```bash
bash scripts/fetch_feeds.sh
bash scripts/convert_openphish_to_misp.sh
# Importer ensuite seed/misp-events/openphish-batch.json dans MISP (UI ou API)
```
