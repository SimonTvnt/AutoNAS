PROJECT_DIR=$(CURDIR)

# Check if .env file exists, if not, copy from .env.sample
check-env:
	@if [ ! -f .env ]; then \
		echo "❌ No .env file found!"; \
		exit 1; \
	fi

up: check-env
	set -a; source .env; set +a; docker compose up -d

down: check-env
	set -a; source .env; set +a; docker compose down

build: check-env
	set -a; source .env; set +a; docker compose build

up-build: check-env
	set -a; source .env; set +a; docker compose up -d --build

logs:
	docker compose logs -f

restart: check-env
	set -a; source .env; set +a; docker compose up -d --force-recreate

update: check-env
	set -a; source .env; set +a; docker compose pull && docker compose up -d

deploy: check-env
	set -a; source .env; set +a; docker compose build && docker compose pull && docker compose up -d

clean: check-env
	set -a; source .env; set +a; docker compose down -v --remove-orphans

backup:
	$(PROJECT_DIR)/scripts/backup_nas.sh

check-vpn:
	$(PROJECT_DIR)/scripts/check_vpn.sh --once

.PHONY: check-env up down build up-build logs restart update deploy clean backup check-vpn