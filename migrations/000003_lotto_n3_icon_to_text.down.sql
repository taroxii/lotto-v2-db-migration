-- 000003_lotto_n3_icon_to_text.down.sql
--
-- Revert icon text -> bytea. Existing URL/text values are re-encoded as UTF-8 bytes,
-- so no data is lost on rollback (the stored string simply becomes its byte form).
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'lotto_n3_game'
          AND column_name = 'icon'
          AND data_type = 'text'
    ) THEN
        ALTER TABLE public.lotto_n3_game
            ALTER COLUMN icon TYPE bytea
            USING convert_to(icon, 'UTF8');
    END IF;
END
$$;
