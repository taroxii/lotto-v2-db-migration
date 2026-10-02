-- 000006_baseline_remaining_tables.up.sql
--
-- BASELINE MIGRATION (idempotent) — final reconciliation against the LIVE
-- lotto_stg schema. Adds domain tables that exist on staging but were never
-- captured by either the backend golang-migrate set (000001–000002, which is an
-- OLD snapshot) or the N3/reward baselines (000004/000005).
--
-- Captured from lotto_stg 2026-09-30 — see docs/stg-snapshot/missing-tables-ddl.txt.
-- All statements are IF NOT EXISTS / guarded; down = no-op (data-bearing on stg).
--
-- Tables added here:
--   admin               (uuid pk — SUPERSEDES the old `admins` table from 000001)
--   huay_configuration  (Thai "หวยปกติ" game config)
--   lotto_n3_item_order (N3 flattened bet rows — Liquibase 0012-add-lotto-n3-item-order)
--   lotto_reward        (reward number config)
--   reward_items        (claimable reward items per order item)
--   user_invite         (referral invite links)

-- 0) admins -> admin reconciliation ---------------------------------------------
-- 000001 (old backend snapshot) created `admins`. Staging has since replaced it
-- with `admin` (uuid pk). On a fresh DB we drop the stale empty `admins` created
-- by 000001 and create `admin`. On staging `admins` does not exist, so the DROP
-- is a no-op and `admin` already exists (CREATE IF NOT EXISTS no-op).
-- NOTE: `admins` from 000001 is freshly-created and empty in the migrate chain,
-- so dropping it loses no data. (Guard with a row-count check to be safe.)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema='public' AND table_name='admins')
       AND NOT EXISTS (SELECT 1 FROM public.admins LIMIT 1) THEN
        DROP TABLE public.admins;
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS public.admin (
    id         uuid PRIMARY KEY,
    username   character varying,
    password   character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);
CREATE UNIQUE INDEX IF NOT EXISTS admin_un     ON public.admin (username);
CREATE INDEX        IF NOT EXISTS admin_id_idx ON public.admin (id, username);

-- 1) huay_configuration (หวยปกติ) -----------------------------------------------
CREATE TABLE IF NOT EXISTS public.huay_configuration (
    id                       integer,
    code                     character varying,
    restrict                 json,
    prize_three_multiple     integer,
    prize_two_top            integer,
    prize_two_bottom         integer,
    prize_top_running_number integer,
    open_date_time           timestamp without time zone,
    close_date_time          timestamp without time zone,
    prize_three_top          integer,
    prize_fourth_top         integer,
    reward                   json
);

-- 2) lotto_n3_item_order (Liquibase 0012-add-lotto-n3-item-order) ----------------
CREATE TABLE IF NOT EXISTS public.lotto_n3_item_order (
    id         uuid PRIMARY KEY,
    game_id    bigint NOT NULL,
    period_id  bigint NOT NULL,
    bet_number character varying(10) NOT NULL,
    bet_type   character varying(50) NOT NULL,
    amount     numeric NOT NULL,
    status     character varying(50),
    user_id    bigint,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    updated_at timestamp without time zone
);
CREATE INDEX IF NOT EXISTS idx_lotto_n3_item_order_game_period
    ON public.lotto_n3_item_order (game_id, period_id);

-- 3) lotto_reward ---------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS public.lotto_reward_id_seq1;
CREATE TABLE IF NOT EXISTS public.lotto_reward (
    id             integer PRIMARY KEY DEFAULT nextval('public.lotto_reward_id_seq1'),
    type           character varying NOT NULL,
    reward         integer NOT NULL,
    config_id      integer NOT NULL,
    number         character varying NOT NULL,
    description    character varying NOT NULL,
    description_th character varying,
    created_at     timestamp without time zone,
    updated_at     timestamp without time zone,
    date           date,
    name           character varying
);
CREATE INDEX IF NOT EXISTS lotto_reward_reward_idx ON public.lotto_reward (reward);

-- 4) reward_items ---------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS public.items_reward_id_seq;
CREATE TABLE IF NOT EXISTS public.reward_items (
    id             integer PRIMARY KEY DEFAULT nextval('public.items_reward_id_seq'),
    description    character varying NOT NULL,
    number         character varying NOT NULL,
    total_reward   integer NOT NULL,
    description_th character varying,
    is_claim       boolean,
    order_item_id  integer NOT NULL,
    created_at     timestamp without time zone,
    updated_at     timestamp without time zone
);

-- 5) user_invite ----------------------------------------------------------------
-- FK references users(invite_link) -> needs a unique index on users.invite_link.
CREATE UNIQUE INDEX IF NOT EXISTS users_invite_link_uk ON public.users (invite_link);
CREATE TABLE IF NOT EXISTS public.user_invite (
    user_id      integer,
    invite_link  character varying,
    credit_usage integer,
    redeem       boolean,
    CONSTRAINT user_invite_fk
        FOREIGN KEY (user_id) REFERENCES public.users (id),
    CONSTRAINT user_invite_fk_invkey
        FOREIGN KEY (invite_link) REFERENCES public.users (invite_link)
        ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS user_invite_un ON public.user_invite (invite_link, user_id);
