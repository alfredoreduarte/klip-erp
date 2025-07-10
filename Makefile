# Simple Makefile for local dev & deployment

.PHONY: setup up down build test deploy backup restore help migrate

setup:
	asdf install
	cd services/store && bundle install && yarn install || true

up:
	docker compose up -d --build

down:
	docker compose down

build:
	docker compose build

test:
	cd services/store && bundle exec rails db:test:prepare && bundle exec rails test

deploy:
	./deploy.sh

backup:
	./scripts/backup/backup.sh

restore:
	@echo "Usage: make restore BACKUP_FILE=path/to/backup.sql.gz"
	@if [ -z "$(BACKUP_FILE)" ]; then echo "Please specify BACKUP_FILE"; exit 1; fi
	./scripts/backup/restore.sh $(BACKUP_FILE)

migrate:
	docker compose exec store bin/rails db:migrate

help:
	@echo "Available targets:"
	@echo "  setup   - Install dependencies and set up the project"
	@echo "  up      - Start all services with Docker Compose"
	@echo "  down    - Stop all services"
	@echo "  build   - Build Docker images"
	@echo "  test    - Run the test suite"
	@echo "  deploy  - Deploy using blue-green deployment"
	@echo "  backup  - Create database backup"
	@echo "  restore - Restore from backup (usage: make restore BACKUP_FILE=path/to/backup.sql.gz)"
	@echo "  migrate - Run database migrations inside the store container"
	@echo "  help    - Show this help message"