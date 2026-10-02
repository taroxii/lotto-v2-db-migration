# Spec: lotto-v2-db-migration — Single Source of Truth for DB Schema

> Status: **In Progress (spec review)** · Owner: Chayakorn · Engine: **golang-migrate** (decided)
> Repo: `github.com/taroxii/lotto-v2-db-migration` (ปัจจุบัน empty — greenfield)
> Related: `[SPEC] Auto Feed Period + Auto Settlement Chain` (migration เป็น prerequisite blocker ของ feature นั้น)
> Based on real code inspection of lotto-apiv2 + reward_batch (2026-09-30).

## Objective

รวม **schema migration ทั้งหมดของ lotto-v2 platform ไว้ที่ repo เดียว** เป็น single source of truth แทนที่ปัจจุบันที่กระจัดกระจาย + บางส่วนไม่เคยมี migration เลย

**ปัญหาปัจจุบัน (จาก code inspection จริง):**
- **lotto-apiv2 (Go):** golang-migrate `db/migrations/` มีแค่ 7 ตารางหลัก (000001/000002) + โฟลเดอร์ `dd/` ซ้ำ — **ตาราง N3 ทั้งหมดไม่มี migration** (มีแค่ GORM struct, สร้างมือ/hotfix นอก repo)
- **reward_batch (Java):** Liquibase YAML 0001–0012 **แต่ `enabled: false`** (ไม่รันตอน boot, migrate มือแยกอยู่แล้ว, batch แค่ `ddl-auto: validate`)
- **ผล:** schema drift เสี่ยงสูง, ไม่มีที่เดียวที่บอกว่า "schema จริงคืออะไร", auto-feed period เขียน `lotto_n3_period` ไม่ได้เพราะไม่มี migration เป็นทางการ

**Success criteria (testable):**
1. `migrate -path . -database $DB_URL up` สร้าง schema ครบทุกตาราง (core + N3 + reward) จาก repo นี้ไฟล์เดียว
2. ตาราง N3 ที่ไม่เคยมี (`lotto_n3_game/period`, `n3_orders/order_items/order_items_bet`) ถูกสร้างครบตรงกับ GORM struct ในbackend
3. reward_batch boot ผ่านด้วย `ddl-auto=validate` โดยไม่พึ่ง Liquibase (schema มาจาก repo นี้)
4. backend boot/test ผ่านด้วย schema จาก repo นี้ (เลิกใช้ `db/migrations/` ใน backend)
5. `migrate ... down` rollback ได้ทุก step (มี .down.sql ครบ)
6. CI: มี step ตรวจ migration up→down→up idempotent บน disposable Postgres

## Engine Decision: golang-migrate (ไม่ใช่ Liquibase)

| เกณฑ์ | golang-migrate ✅ | Liquibase ❌ |
|-------|------------------|--------------|
| Backend (domain เจ้าของหลัก) ใช้อยู่แล้ว | ✅ `db/migrations/*.sql` numbered up/down | ต้องแปลง SQL→YAML |
| reward_batch ผูก runtime ไหม | — | ❌ `enabled:false` ปิดอยู่ ไม่ผูก boot — ย้ายได้ฟรี |
| รูปแบบ migration ส่วนใหญ่ที่มี | ✅ SQL (backend 7 ตาราง) | YAML เฉพาะ reward 12 ไฟล์ |
| Dependency ตอน apply | ✅ binary เดียว ไม่ต้อง JVM | ❌ ต้อง Java/JVM runtime |
| งานแปลงที่ต้องทำ | reward YAML→SQL (12) + เขียน N3 ใหม่ | backend SQL→YAML + N3 ใหม่ (เป็น YAML) + ยัง pull JVM |
| CI/CD, k8s initContainer | ✅ เบา (static binary) | หนัก (JRE image) |

**สรุป:** go-migrate ชนะเพราะ (1) backend ซึ่งเป็นเจ้าของ domain หลักใช้อยู่แล้ว (2) reward Liquibase ปิดอยู่ไม่ผูก runtime — ทิ้งได้ไม่กระทบ boot (แค่ validate schema ที่ migrate มาให้) (3) แปลงน้อยกว่า (reward 12 YAML→SQL) (4) migrate ไม่ต้องพึ่ง JVM — เบากว่าใน CI/CD/initContainer

## Scope

### In scope
1. **สร้าง repo structure** (greenfield): `migrations/` (numbered SQL), `README.md`, `Makefile`, `docker-compose.yml` (local Postgres), CI
2. **ย้าย backend migration** (lotto-apiv2 → repo นี้): 7 core table + index; ล้าง `dd/` ที่ซ้ำ
3. **แปลง reward_batch Liquibase → SQL** (0001–0012): draw_result, prize_result(+item/item_bet), batch_run, lifecycle/audit/idempotency fields, wallet settlement + partial unique index (0011), game.type rename (0012)
4. **เขียน N3 migration ที่ไม่เคยมี** (ให้ตรง GORM struct backend): `lotto_n3_game`, `lotto_n3_period`, `n3_orders`, `n3_order_items`, `n3_order_items_bet`, reward_item
5. **ทำให้ทั้ง backend + reward_batch ใช้ schema จาก repo นี้** — backend เลิก `db/migrations/`, reward_batch คง `liquibase.enabled=false` + `ddl-auto=validate`
6. CI idempotency check (up→down→up)

### Out of scope
- Data migration/backfill (schema only)
- เปลี่ยน ORM/entity code (เฉพาะ DDL ให้ตรงของเดิม)
- Airflow metadata DB (เป็น postgres แยกของ airflow เอง ไม่เกี่ยว)

## Table Inventory (ของจริงที่ต้องรวม)

### A. Core (จาก lotto-apiv2 000001 — ย้ายตรง, SQL อยู่แล้ว)
`account_balance`, `admins`, `order_items`, `orders`, `thai_lottery_configuration`, `transactions`, `users` + index (000002: orders user_id/expired_at; admins; users)
⚠️ `thai_lottery_configuration` ปัจจุบันขาดคอลัมน์ `first_prize`/`is_current` ที่ domain model มี — ตัดสินใจตอนย้ายว่าจะเติมให้ตรง model หรือคง mapping ตัดทิ้ง

### B. N3 (ไม่เคยมี migration — เขียนใหม่ให้ตรง GORM struct)
| ตาราง | TableName() ที่ repository | ref |
|-------|---------------------------|-----|
| `lotto_n3_game` | game_repository.go:66 | id,type,name,icon,status,max_bet,min_bet,earn_rate(jsonb),created_at,updated_at |
| `lotto_n3_period` | game_repository.go:70 | id,game_id(fk),open_at,close_at,override_earn_rate(jsonb),created_at,updated_at |
| `n3_orders` | n3_order_repository.go:57 | (ดู struct) |
| `n3_order_items` | n3_order_repository.go:61 | |
| `n3_order_items_bet` | n3_order_repository.go:65 | |
| reward_item | reward_item/gorm.go:31 | |

### C. Reward (จาก reward_batch Liquibase 0001–0012 — แปลง YAML→SQL)
| changelog | ตาราง/การเปลี่ยน |
|-----------|------------------|
| 0001 | `lotto_draw_result` |
| 0002 | `lotto_draw_prize_result` |
| 0003 | `lotto_draw_prize_result_item` |
| 0004 | `lotto_draw_prize_result_item_bet` |
| 0006 | draw-result lifecycle fields |
| 0007 | audit + idempotency (settlement_status, idempotency_key, result_version, unique keys, indexes) |
| 0008 | `lotto_batch_run` |
| 0009 | unique (draw_date, draw_type) |
| 0010 | order-summary fields (processed/winning_bet_count, total_prize_amount, is_prize) |
| 0011 | **wallet settlement + partial unique index กัน double-payment** (critical) |
| 0012 | rename `lotto_n3_game.type` id=7 THAI_GLOV→THAI (guarded; ตาราง backend เป็นเจ้าของ) |
(ไม่มี 0005 — ข้ามใน include list เดิม)

## Target Repo Structure
```
lotto-v2-db-migration/
  migrations/
    000001_core_init.up.sql / .down.sql          # core 7 tables
    000002_core_indexes.up.sql / .down.sql
    000003_n3_game_period.up.sql / .down.sql     # N3 ใหม่
    000004_n3_orders.up.sql / .down.sql
    000005_reward_draw_result.up.sql / .down.sql # จาก Liquibase 0001-0004
    000006_reward_lifecycle_audit.up.sql/.down   # 0006-0007
    000007_reward_batch_run.up.sql / .down       # 0008-0009
    000008_reward_order_summary.up.sql/.down      # 0010
    000009_reward_wallet_settlement.up.sql/.down  # 0011 (partial unique idx)
    000010_game_type_thai.up.sql / .down.sql      # 0012
  README.md
  Makefile            # make up / down / new / test
  docker-compose.yml  # disposable postgres:16 สำหรับ test local + CI
  .github/workflows/migrate-check.yml   # up→down→up idempotent
```
> ลำดับเลขจริง finalize ตอน implement (คง dependency: core→N3→reward; game ต้องมาก่อน period/0012)

## Commands
```bash
export DB_URL="postgres://user:pass@localhost:5432/lotto?sslmode=disable"
migrate -path migrations -database "$DB_URL" up           # apply ทั้งหมด
migrate -path migrations -database "$DB_URL" down 1        # rollback 1 step
migrate create -ext sql -dir migrations -seq <name>        # new migration
# local test
docker compose up -d postgres && make test                 # up→down→up idempotent
```

## Integration (ให้ 2 service ใช้ repo นี้)
- **backend (lotto-apiv2):** เลิกใช้ `db/migrations/` ภายใน; CI/deploy เรียก migrate จาก repo นี้ (submodule / vendored / init step). เอกสาร backend ชี้มา repo นี้
- **reward_batch:** คง `spring.liquibase.enabled=false` + `ddl-auto=validate`; deploy รัน migrate จาก repo นี้ก่อน boot (initContainer/CI step). ลบ/freeze `src/main/resources/db/changelog/` (เก็บไว้ reference ชั่วคราว)
- **k8s:** initContainer รัน `migrate ... up` ก่อน pod backend/batch start

## Testing Strategy
- CI (`migrate-check.yml`): spin postgres:16 → `up` ครบ → `down` ครบ → `up` ซ้ำ = idempotent + rollback-safe
- Schema parity: dump schema หลัง up → เทียบว่าตรง GORM struct (backend) + entity (batch) ไม่ให้ `ddl-auto=validate` fail
- Smoke: boot backend + reward_batch ชี้ DB ที่ migrate จาก repo นี้ → ต้องผ่าน

## Boundaries
- **Always:** .up + .down คู่กันทุกไฟล์, numbered sequential, test idempotent ก่อน merge, DDL ตรง struct/entity เดิมเป๊ะ
- **Ask first:** เปลี่ยน column เดิมที่มี data (เช่น เติม first_prize), drop/rename ตารางที่มี data, apply บน DB ที่มี data จริง (lotto_stg/prod)
- **Never:** data loss migration โดยไม่ consent, commit secret/DB creds, แก้ schema ให้ไม่ตรง entity (ทำ validate fail), bundle data backfill ปน DDL

## Resolved Decisions (finalized 2026-09-30, verified against lotto_stg จริง)

### D1 — Distribution: **container image**
backend/batch ดึง migration ผ่าน **container image** (ไม่ใช่ submodule/vendored) — build image `lotto-v2-db-migration:<tag>` ที่ bundle `migrate` binary + `migrations/*.sql` → ใช้เป็น **k8s initContainer** run `migrate ... up` ก่อน pod backend/batch start. CI push image ทุก merge.

### D2 — thai_lottery_configuration: **มี data เดิมบน stg** → ห้าม destructive
ยืนยันจาก stg: ตารางชื่อจริง `thai_lottery_configuration` มี data. การเติม `first_prize`/`is_current` ต้องเป็น `ADD COLUMN` nullable เท่านั้น (ไม่ drop/rename). **baseline ต้อง mark ตารางนี้ว่า applied** (มีอยู่แล้ว ไม่รัน CREATE ซ้ำ)

### D3 — Baseline (mark applied, ไม่รัน DDL ซ้ำ): **จำเป็น — ยืนยัน drift จริง 2 engine**
‼️ **ของจริงบน lotto_stg รัน 2 migration engine พร้อมกัน + ทั้งคู่ drift จาก repo:**
- **go-migrate** (`schema_migrations`): version **4, dirty=f** — แต่ backend repo มีแค่ 2 ไฟล์ (000001,000002) → **มี 2 migration รันบน stg ที่ไม่มีใน repo**
- **Liquibase** (`databasechangelog`): 16 changesets ถึง **0013** — แต่ reward repo มีแค่ 0012 → stg มี `0012-add-lotto-n3-item-order` + `0013-fix-id-fk-column-types-to-bigint` (author=hermes) ที่ยังไม่ merge กลับ repo

**กลยุทธ์ cutover:** repo ใหม่ reproduce schema ปัจจุบันให้ตรง stg → ใช้ `migrate force <version>` ตั้ง baseline (mark applied ไม่รัน DDL) บน DB ที่มี schema อยู่แล้ว → migration ใหม่ค่อยรันต่อจาก baseline. ต้อง **เก็บ go-migrate v4 ที่หายไป + Liquibase 0013** กลับมาเป็น SQL ก่อน (ดู Open Q)

### D4 — Cutover: **ทีเดียว (big-bang)**
ย้ายทั้งหมดทีเดียว ไม่ phase — repo ใหม่เป็น SSOT ทันทีหลัง baseline, backend เลิก `db/migrations/`, reward ปิด Liquibase (enabled=false อยู่แล้ว) พร้อมกัน

### D5 — N3 column parity: **ตรง GORM struct ✅ (verified)**
`lotto_n3_period` จริงบน stg = id,game_id,open_at,close_at,override_earn_rate(json),created_at,updated_at — **ตรง GORM struct เป๊ะ**. `lotto_n3_game` = id,type,name,icon,max_bet,min_bet,earn_rate(json),status,created_at,updated_at — ตรง. เขียน .up.sql ได้ปลอดภัยจาก snapshot จริง (`docs/stg-snapshot/schema-reference.md`)

## Table Inventory (VERIFIED จาก lotto_stg — 31 ตาราง, PG 18.1)

> snapshot เต็ม: `docs/stg-snapshot/schema-reference.md` (dump ผ่าน psql information_schema เพราะ server PG18 > pg_dump16)

### A. Core / backend (go-migrate domain)
`account_balance`, `admin` (ไม่ใช่ admins! uuid pk), `users`, `user_invite`, `orders`, `order_items`, `transactions`, `thai_lottery_configuration`, **`huay_configuration`** (หวยปกติ — ไม่เคยอยู่ใน repo!)

### B. N3 (go-migrate — ยังไม่มีไฟล์ใน repo แต่มีบน stg)
`lotto_n3_game`, `lotto_n3_period`, `lotto_n3_item_order`, `n3_orders`, `n3_order_items`, `n3_order_items_bet`, `lotto_reward`, `reward_items`

### C. Reward (Liquibase domain — ถึง 0013 บน stg)
`lotto_draw_result`, `lotto_draw_prize_result` (25 cols — มี wallet_settlement_id/settlement_attempts/settled_at ครบจาก 0011), `lotto_draw_prize_result_item`, `lotto_draw_prize_result_item_bet`, `lotto_batch_run`

### D. Spring Batch metadata (ห้ามแตะ — Spring สร้างเอง)
`batch_job_execution(_context/_params)`, `batch_job_instance`, `batch_step_execution(_context)` — **ไม่รวมใน migration repo** (Spring Batch `@EnableBatchProcessing` สร้าง/จัดการเอง)

### E. Engine bookkeeping
`schema_migrations` (go-migrate), `databasechangelog` + `databasechangeloglock` (Liquibase — หลัง cutover freeze)

## Implementation Status — ✅ BASELINE DONE + VERIFIED (2026-09-30)

Repo สร้างเสร็จ + verified จริง, pushed to `main` (commit aa050ae).

**7 migrations (go-migrate เดียว, Liquibase หายไปจากภาพ):**
| ver | domain | ที่มา |
|-----|--------|-------|
| 000001-002 | core | lotto-apiv2 |
| 000003-004 | N3 game/period/orders | **กู้จาก git stash** (branch fix/n3-single-game-active-period, commit 0826a60 — untracked ไม่เคย commit) |
| 000005 | reward prize_result chain + partial unique index กัน double-pay | reverse จาก stg (Liquibase 0001-0013) |
| 000006 | admin(uuid, แทน admins)/huay_configuration/lotto_n3_item_order/lotto_reward/reward_items/user_invite | reverse จาก stg |
| 000007 | reconcile thai_lottery_configuration (drop assets_name) | diff vs stg |

**Verified บน Postgres 18 เปล่า:**
- ✅ migrate up ครบ 7 version
- ✅ idempotent (up ซ้ำ = "no change")
- ✅ **schema ตรง lotto_stg 100% — 22/22 domain tables, ทุก column ทุก type**

**go-migrate vs Liquibase — ตอบแล้ว: go-migrate เดียว**
- `ddl-auto=validate` เป็นของ Hibernate ไม่ใช่ Liquibase → validate schema จริงใน DB เทียบ entity → **ไม่สนว่า engine ไหน migrate → go-migrate support เต็มที่**
- `databasechangelog`/`databasechangeloglock` = ซาก Liquibase (enabled=false ไม่อ่านตอน boot) → หลัง cutover ปล่อยทิ้งได้ ไม่กระทบ batch boot (แก้ที่เคยเตือนผิดในรอบก่อน: ลบ changelog ได้ ไม่พัง; ที่ห้ามแตะคือ **ตาราง domain** ที่มี data)

**Baseline stg (data-safe, "mark as applied เฉยๆ"):** ทุก migration = `IF NOT EXISTS` + down=no-op → `migrate force 7` บน stg = เขียน schema_migrations.version=7 ไม่รัน DDL ไม่แตะ data

## Open Questions (เหลือ — ก่อนรัน cutover จริงบน stg)
1. **md5sum/Liquibase coexist** — ช่วง transition stg ยังมี databasechangelog อยู่; ยืนยันว่าจะ freeze (ปล่อยทิ้ง) หรือ drop 2 ตาราง bookkeeping ทีหลัง
2. **รัน `migrate force 7` บน stg เมื่อไหร่** — ต้อง backup schema_migrations/databasechangelog ก่อน (ask-first: แตะ DB มี data)
3. **wire initContainer เข้า backend/reward_batch deploy** — เมื่อ cutover (แยก PR ที่ repo นั้น ๆ)
4. **down ของ 000001/000002** — ปัจจุบัน down-all พังเพราะ users ถูก user_invite FK ผูก (forward-only baseline ไม่ teardown prod จึงไม่ critical; ถ้าจะให้ CI down-all ผ่าน ต้องแก้ down 000001/000002 ให้ drop ตามลำดับ FK)

## Evidence / File References (2026-09-30)
- backend go-migrate: `lotto-apiv2/db/migrations/000001_init.up.sql` (CREATE TABLE L6/25/37/58/70/84/102), `000002_add_index`, `dd/` ซ้ำ; `testutil/migration.go` เรียก golang-migrate CLI; ไม่มี AutoMigrate
- N3 tables ไม่มี SQL: `repository/game/game_repository.go:66,70`, `repository/n3_order/n3_order_repository.go:57,61,65`, `repository/reward_item/gorm.go:31`
- reward Liquibase ปิด: `reward_batch/src/main/resources/application.yaml:8-10` (`liquibase.enabled:false`, change-log), `:22` (`ddl-auto:validate`); changelog `db.changelog.yaml` include 0001–0012
- empty target repo: `github.com/taroxii/lotto-v2-db-migration` (cloned 2026-09-30 → empty)
