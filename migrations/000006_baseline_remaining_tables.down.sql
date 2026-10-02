-- 000006_baseline_remaining_tables.down.sql
--
-- Intentionally a NO-OP (baseline of pre-existing, data-bearing staging tables).
-- Dropping admin / huay_configuration / lotto_n3_item_order / lotto_reward /
-- reward_items / user_invite would destroy live data. A real teardown must be a
-- dedicated, reviewed migration.
SELECT 1;
