# Simple Makefile for local dev & deployment

.PHONY: setup up down build test deploy

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
	cd services/store && bundle exec rake db:test:prepare && bundle exec rake

deploy:
	./deploy.sh