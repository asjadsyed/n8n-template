.DEFAULT_GOAL := export-workflows

.PHONY: export-workflows
export-workflows:
	docker-compose run --rm \
		-v ./n8n-data/workflows:/opt/n8n/workflows \
		n8n \
		export:workflow --backup --output /opt/n8n/workflows

.PHONY: import-workflows
import-workflows:
	docker-compose run --rm \
		-v ./n8n-data/workflows:/opt/n8n/workflows \
		n8n \
		import:workflow --input /opt/n8n/workflows --separate
