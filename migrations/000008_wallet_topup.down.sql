-- 000008_wallet_topup.down.sql
--
-- Reverse the additive wallet/top-up changes. The balance type change is NOT
-- reverted (NUMERIC -> INTEGER would truncate satang = data loss); documented
-- as forward-only, matching the baseline no-op-down discipline for money data.

DROP INDEX IF EXISTS public.transactions_status_type_idx;
DROP INDEX IF EXISTS public.transactions_account_created_idx;
DROP INDEX IF EXISTS public.transactions_idempotency_key_uidx;

ALTER TABLE public.transactions DROP COLUMN IF EXISTS idempotency_key;
ALTER TABLE public.transactions DROP COLUMN IF EXISTS bank_reference;
ALTER TABLE public.transactions DROP COLUMN IF EXISTS slip_url;

-- NOTE: account_balance.balance is intentionally left as NUMERIC(14,2).
-- Reverting to INTEGER would truncate satang and lose money data.
SELECT 1;
