# lotto-v2-db-migration

**Single source of truth** for the entire lotto-v2 platform database schema.
Engine: [golang-migrate](https://github.com/golang-migrate/migrate). Postgres.

Consolidates schema previously split across two tools and two repos:
- **lotto-apiv2** (Go backend) — core + N3 game domain (was golang-migrate, incomplete)
- **reward_batch** (Java) — reward/settlement domain (was Liquibase, `enabled:false`)

After cutover, **both services stop running their own migrations**. This repo is
the only thing that touches DDL. reward_batch keeps `spring.liquibase.enabled=false`
and `ddl-auto=validate` — Hibernate validates entities against whatever schema this
repo produced (it does not care which engine built it).

## Migrations

| file | domain | notes |
|------|--------|-------|
| `000001_init` | core | account_balance, admin, users, orders, order_items, transactions, thai_lottery_configuration (from lotto-apiv2) |
| `000002_add_index` | core | indexes |
| `000003_lotto_n3_icon_to_text` | N3 | icon bytea→text (idempotent guard) |
| `000004_baseline_lotto_n3_schema` | N3 | lotto_n3_game/period, n3_orders/items/bet (IF NOT EXISTS; down=no-op) |
| `000005_reward_baseline` | reward | lotto_draw_result, prize_result(+item/bet), batch_run + **partial unique idx กัน double-payment** (from Liquibase 0001–0013; IF NOT EXISTS; down=no-op) |

All baselines are **idempotent** (`IF NOT EXISTS` / guarded `DO $$`): safe to run on a
fresh DB (recreates schema) or an existing data-bearing DB (no-op).

## Usage

```bash
export DB_URL="postgres://user:pass@localhost:5432/lotto?sslmode=disable"

make up              # apply all migrations
make down            # roll back 1 step
make new name=foo    # create a new migration pair
make test            # spin disposable postgres, run up→down→up (idempotency check)

# raw:
migrate -path migrations -database "$DB_URL" up
```

## Baseline an existing database (staging/prod — data already present)

The existing DB already has the schema (built previously by the old tools). Do NOT
re-run DDL. Just mark the baseline as applied so future migrations continue cleanly:

```bash
# mark as applied WITHOUT running any DDL (data-safe):
migrate -path migrations -database "$DB_URL" force 5
```

`force 5` writes `schema_migrations.version = 5, dirty = false` and runs nothing.
Because every baseline is `IF NOT EXISTS`, even an accidental `up` would be a no-op —
`force` is the clean, explicit way.

## Distribution (container image → k8s initContainer)

CI builds `lotto-v2-db-migration:<tag>` (migrate binary + migrations/). backend and
reward_batch pods run it as an **initContainer** (`migrate ... up`) before the app
starts. See `Dockerfile`.
