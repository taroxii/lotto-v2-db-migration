-- 000003_lotto_n3_icon_to_text.up.sql
--
-- Context: lotto_n3_game / lotto_n3_period / n3_* tables were originally created
-- outside this migration set (GORM/manual). This migration is the first backend
-- migration to formally touch the N3 game schema. It is written idempotently so it
-- is safe to run against a database where those tables already exist with data.
--
-- Change: the "icon" column historically stored a base64-encoded image blob as bytea.
-- Icons now live in object storage (MinIO bucket "game-icons") and the column stores
-- only the public URL string. Convert bytea -> text so the column reflects its real
-- semantics and is queryable/indexable.

-- Guard: only convert if the column is still bytea (idempotent re-runs are no-ops).
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'lotto_n3_game'
          AND column_name = 'icon'
          AND data_type = 'bytea'
    ) THEN
        ALTER TABLE public.lotto_n3_game
            ALTER COLUMN icon TYPE text
            USING convert_from(icon, 'UTF8');
    END IF;
END
$$;
