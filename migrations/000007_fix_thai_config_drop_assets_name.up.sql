-- 000007_fix_thai_config_drop_assets_name.up.sql
--
-- Reconcile thai_lottery_configuration to the LIVE lotto_stg schema.
--
-- 000001 (old backend snapshot) defines an `assets_name` column that does NOT
-- exist on staging — staging dropped it (or 000001 predates the drop). To make the
-- baseline faithfully match production, drop it here.
--
-- Idempotent + data-safe:
--   * on staging the column is already absent -> DROP IF EXISTS is a no-op,
--   * on a fresh DB built from 000001 it removes the stray column.
-- Since the column is absent on staging it holds no data; nothing is lost.

ALTER TABLE public.thai_lottery_configuration DROP COLUMN IF EXISTS assets_name;
