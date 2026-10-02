-- 000007_fix_thai_config_drop_assets_name.down.sql
--
-- Re-add assets_name (nullable) to reverse 000007. No data existed, so this is a
-- clean structural rollback.
ALTER TABLE public.thai_lottery_configuration ADD COLUMN IF NOT EXISTS assets_name character varying;
