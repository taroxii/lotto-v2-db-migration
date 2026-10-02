# lotto-v2-db-migration — Makefile
# Requires: golang-migrate CLI (`brew install golang-migrate`), docker (for `test`).

MIGRATE ?= migrate
MIGRATIONS_DIR := migrations
DB_URL ?= postgres://postgres:postgres@localhost:5433/lotto_test?sslmode=disable

.PHONY: up down force new test test-up test-down verify-stg clean

up:
	$(MIGRATE) -path $(MIGRATIONS_DIR) -database "$(DB_URL)" up

down:
	$(MIGRATE) -path $(MIGRATIONS_DIR) -database "$(DB_URL)" down 1

# force a baseline version WITHOUT running DDL (for existing data-bearing DBs)
# usage: make force version=5
force:
	$(MIGRATE) -path $(MIGRATIONS_DIR) -database "$(DB_URL)" force $(version)

# usage: make new name=add_something
new:
	$(MIGRATE) create -ext sql -dir $(MIGRATIONS_DIR) -seq $(name)

# idempotency + rollback check on a disposable postgres
test:
	docker compose up -d postgres
	@echo "waiting for postgres..."
	@until docker compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; do sleep 1; done
	$(MIGRATE) -path $(MIGRATIONS_DIR) -database "$(DB_URL)" up
	$(MIGRATE) -path $(MIGRATIONS_DIR) -database "$(DB_URL)" up   # re-run: must be no-op (idempotent)
	$(MIGRATE) -path $(MIGRATIONS_DIR) -database "$(DB_URL)" down -all
	$(MIGRATE) -path $(MIGRATIONS_DIR) -database "$(DB_URL)" up   # up again after rollback
	@echo "OK: up -> up(noop) -> down-all -> up passed"
	docker compose down -v

clean:
	docker compose down -v
