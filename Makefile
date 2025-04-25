PROJECT_DIR=$(CURDIR)

up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build

up-build:
	docker compose up -d --build

logs:
	docker compose logs -f

restart:
	make down && make up

clean:
	docker compose down -v --remove-orphans

backup:
	$(PROJECT_DIR)/backup_nas.sh

.PHONY: up down build up-build logs restart clean backup
