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

restart: down up

clean: check-env
	set -a; source .env; set +a; docker compose down -v --remove-orphans

backup:
	$(PROJECT_DIR)/backup_nas.sh

.PHONY: check-env up down build up-build logs restart clean backup