.PHONY: up full down logs seed rules test hc
up:
	docker compose -f docker/docker-compose.yml --profile minimal up -d
full:
	docker compose -f docker/docker-compose.yml --profile full up -d
logs:
	docker compose -f docker/docker-compose.yml logs -f --tail=200
seed:
	bash scripts/misp_ingest_sample.sh
rules:
	bash scripts/misp_export_suricata.sh && docker exec -it ${PROJECT_NAME}-suricata-1 suricatasc -c reload-rules || true
test:
	bash scripts/seed_traffic.sh
hc:
	bash scripts/healthcheck.sh
down:
	docker compose -f docker/docker-compose.yml down -v --remove-orphans
