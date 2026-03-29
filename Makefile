PROJECT_DIR=$(CURDIR)

# Check if .env file exists and warn about common misconfigurations
check-env:
	@if [ ! -f .env ]; then \
		echo "❌ No .env file found! Run: cp .env.sample .env"; \
		exit 1; \
	fi
	@if grep -qE "^WIREGUARD_PRIVATE_KEY=your_private_key" .env 2>/dev/null; then \
		echo "❌ WIREGUARD_PRIVATE_KEY is not configured in .env!"; \
		exit 1; \
	fi
	@if grep -qE "^(GLUETUN_PASSWORD|QBIT_PASSWORD)=(adminadmin|change_me)" .env 2>/dev/null; then \
		echo "⚠️  WARNING: Default credentials detected — change GLUETUN_PASSWORD and QBIT_PASSWORD in .env"; \
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

status: check-env
	@set -a; source .env; set +a; docker compose ps
	@echo ""
	@echo "=== VPN Status ==="
	@$(PROJECT_DIR)/scripts/check_vpn.sh --once || true

.PHONY: check-env up down build up-build logs restart update deploy clean backup check-vpn status
