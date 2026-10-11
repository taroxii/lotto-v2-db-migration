-- 000008_wallet_topup.up.sql
--
-- Wallet & Top-up feature. Additive + idempotent + data-safe.
--
--  1. account_balance.balance INTEGER -> NUMERIC(14,2): money needs satang.
--     INTEGER -> NUMERIC is a safe widening cast (no data loss, existing whole
--     values become e.g. 100.00). Guarded so re-runs are no-ops.
--  2. transactions gains slip_url, bank_reference, idempotency_key for bank-transfer
--     top-ups with slip evidence + retry de-duplication.
--  3. partial-unique index on idempotency_key: a client retry with the same key
--     cannot create a second pending top-up (duplicate-credit prevention, R6).
--
-- Credit still happens ONLY on admin approve (existing confirm flow) — a slip is
-- never sufficient to credit a wallet.

-- 1) balance -> NUMERIC(14,2) (idempotent: only convert if still integer)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='account_balance'
      AND column_name='balance' AND data_type='integer'
  ) THEN
    ALTER TABLE public.account_balance
      ALTER COLUMN balance TYPE NUMERIC(14,2) USING balance::numeric(14,2);
  END IF;
  -- keep the default sane after the type change
  ALTER TABLE public.account_balance ALTER COLUMN balance SET DEFAULT 0;
END $$;

-- 2) top-up evidence + idempotency columns on transactions
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS slip_url        character varying;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS bank_reference  character varying;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS idempotency_key character varying;

-- 3) de-dupe top-up retries: same key cannot create two pending top-ups
CREATE UNIQUE INDEX IF NOT EXISTS transactions_idempotency_key_uidx
  ON public.transactions (idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- helpful for the self-history and admin-queue queries
CREATE INDEX IF NOT EXISTS transactions_account_created_idx
  ON public.transactions (account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS transactions_status_type_idx
  ON public.transactions (status, type);
