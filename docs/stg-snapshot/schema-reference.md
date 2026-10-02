# lotto_stg schema snapshot (PG 18.1, via psql information_schema)

## account_balance (10 cols)
  - id integer NOT NULL
  - bank_code character varying NOT NULL
  - bank_name character varying NOT NULL
  - account_number character varying NOT NULL
  - balance integer
  - user_id integer
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - deleted_at timestamp without time zone
  - account_name character varying NOT NULL

## admin (6 cols)
  - id uuid NOT NULL
  - username character varying
  - password character varying
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - deleted_at timestamp without time zone

## batch_job_execution (10 cols)
  - job_execution_id bigint NOT NULL
  - version bigint
  - job_instance_id bigint NOT NULL
  - create_time timestamp without time zone NOT NULL
  - start_time timestamp without time zone
  - end_time timestamp without time zone
  - status character varying(10)
  - exit_code character varying(2500)
  - exit_message character varying(2500)
  - last_updated timestamp without time zone

## batch_job_execution_context (3 cols)
  - job_execution_id bigint NOT NULL
  - short_context character varying(2500) NOT NULL
  - serialized_context text

## batch_job_execution_params (5 cols)
  - job_execution_id bigint NOT NULL
  - parameter_name character varying(100) NOT NULL
  - parameter_type character varying(100) NOT NULL
  - parameter_value character varying(2500)
  - identifying character(1) NOT NULL

## batch_job_instance (4 cols)
  - job_instance_id bigint NOT NULL
  - version bigint
  - job_name character varying(100) NOT NULL
  - job_key character varying(32) NOT NULL

## batch_step_execution (19 cols)
  - step_execution_id bigint NOT NULL
  - version bigint NOT NULL
  - step_name character varying(100) NOT NULL
  - job_execution_id bigint NOT NULL
  - create_time timestamp without time zone NOT NULL
  - start_time timestamp without time zone
  - end_time timestamp without time zone
  - status character varying(10)
  - commit_count bigint
  - read_count bigint
  - filter_count bigint
  - write_count bigint
  - read_skip_count bigint
  - write_skip_count bigint
  - process_skip_count bigint
  - rollback_count bigint
  - exit_code character varying(2500)
  - exit_message character varying(2500)
  - last_updated timestamp without time zone

## batch_step_execution_context (3 cols)
  - step_execution_id bigint NOT NULL
  - short_context character varying(2500) NOT NULL
  - serialized_context text

## databasechangelog (14 cols)
  - id character varying(255) NOT NULL
  - author character varying(255) NOT NULL
  - filename character varying(255) NOT NULL
  - dateexecuted timestamp without time zone NOT NULL
  - orderexecuted integer NOT NULL
  - exectype character varying(10) NOT NULL
  - md5sum character varying(35)
  - description character varying(255)
  - comments character varying(255)
  - tag character varying(255)
  - liquibase character varying(20)
  - contexts character varying(255)
  - labels character varying(255)
  - deployment_id character varying(10)

## databasechangeloglock (4 cols)
  - id integer NOT NULL
  - locked boolean NOT NULL
  - lockgranted timestamp without time zone
  - lockedby character varying(255)

## huay_configuration (12 cols)
  - id integer
  - code character varying
  - restrict json
  - prize_three_multiple integer
  - prize_two_top integer
  - prize_two_bottom integer
  - prize_top_running_number integer
  - open_date_time timestamp without time zone
  - close_date_time timestamp without time zone
  - prize_three_top integer
  - prize_fourth_top integer
  - reward json

## lotto_batch_run (9 cols)
  - id bigint NOT NULL
  - job_execution_id bigint
  - status character varying(32) NOT NULL
  - draw_date date
  - draw_type character varying(32)
  - draw_result_id bigint
  - created_at timestamp without time zone NOT NULL
  - updated_at timestamp without time zone
  - failure_reason text

## lotto_draw_prize_result (25 cols)
  - id bigint NOT NULL
  - game_id bigint NOT NULL
  - period_id bigint NOT NULL
  - n3_orders_id uuid NOT NULL
  - matched_count integer
  - processed boolean
  - batch_run_id uuid
  - draw_result_id bigint
  - evaluation_status character varying(32)
  - settlement_status character varying(32)
  - idempotency_key character varying(128)
  - result_version integer NOT NULL
  - evaluated_at timestamp without time zone
  - settlement_ready_at timestamp without time zone
  - last_error text
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - processed_bet_count integer NOT NULL
  - winning_bet_count integer NOT NULL
  - total_prize_amount numeric NOT NULL
  - is_prize boolean NOT NULL
  - wallet_settlement_id character varying(128)
  - settlement_attempts integer NOT NULL
  - settled_at timestamp without time zone
  - settlement_attempted_at timestamp without time zone

## lotto_draw_prize_result_item (11 cols)
  - id bigint NOT NULL
  - lotto_draw_prize_result bigint NOT NULL
  - won_prize_amount numeric NOT NULL
  - processed_at timestamp without time zone NOT NULL
  - is_prize boolean
  - item_id bigint
  - evaluation_status character varying(32)
  - matched_rule_code character varying(64)
  - result_version integer NOT NULL
  - created_at timestamp without time zone
  - updated_at timestamp without time zone

## lotto_draw_prize_result_item_bet (14 cols)
  - id bigint NOT NULL
  - lotto_draw_prize_result_item_id bigint NOT NULL
  - bet_id bigint NOT NULL
  - amount numeric NOT NULL
  - prize_rate numeric NOT NULL
  - total_prize_amount numeric NOT NULL
  - processed_at timestamp without time zone NOT NULL
  - bet_number character varying(16)
  - bet_type character varying(32)
  - evaluation_status character varying(32)
  - matched_rule_code character varying(64)
  - result_version integer NOT NULL
  - created_at timestamp without time zone
  - updated_at timestamp without time zone

## lotto_draw_result (18 cols)
  - id bigint NOT NULL
  - title character varying(255) NOT NULL
  - six_digit character varying(6)
  - four_digit character varying(64)
  - suffix_three_digit character varying(255)
  - suffix_two_digit character varying(255)
  - two_digit character varying(255)
  - animal character varying(128)
  - draw_type character varying(32) NOT NULL
  - draw_date date NOT NULL
  - draw_id bigint
  - scraped_at_utc timestamp without time zone
  - created_at timestamp without time zone NOT NULL
  - status character varying(32) NOT NULL
  - source_ref character varying(255)
  - publication_version integer NOT NULL
  - published_at timestamp without time zone
  - updated_at timestamp without time zone

## lotto_n3_game (10 cols)
  - id bigint NOT NULL
  - type character varying
  - name character varying NOT NULL
  - icon text
  - max_bet integer
  - min_bet integer
  - earn_rate json NOT NULL
  - status character varying
  - created_at timestamp without time zone
  - updated_at timestamp without time zone

## lotto_n3_item_order (10 cols)
  - id uuid NOT NULL
  - game_id bigint NOT NULL
  - period_id bigint NOT NULL
  - bet_number character varying(10) NOT NULL
  - bet_type character varying(50) NOT NULL
  - amount numeric NOT NULL
  - status character varying(50)
  - user_id bigint
  - created_at timestamp without time zone NOT NULL
  - updated_at timestamp without time zone

## lotto_n3_period (7 cols)
  - id bigint NOT NULL
  - game_id bigint NOT NULL
  - open_at timestamp without time zone NOT NULL
  - close_at timestamp without time zone NOT NULL
  - override_earn_rate json
  - created_at timestamp without time zone NOT NULL
  - updated_at timestamp without time zone

## lotto_reward (11 cols)
  - type character varying NOT NULL
  - reward integer NOT NULL
  - config_id integer NOT NULL
  - id integer NOT NULL
  - number character varying NOT NULL
  - description character varying NOT NULL
  - description_th character varying
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - date date
  - name character varying

## n3_order_items (8 cols)
  - id bigint NOT NULL
  - n3_orders_id uuid NOT NULL
  - type character varying NOT NULL
  - earn_rate real NOT NULL
  - is_paid boolean
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - amount real

## n3_order_items_bet (4 cols)
  - item_id bigint NOT NULL
  - number character varying(4)
  - amount real
  - id bigint NOT NULL

## n3_orders (11 cols)
  - id uuid NOT NULL
  - type character varying
  - state character varying
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - description character varying
  - user_id bigint
  - expired_at timestamp without time zone
  - game_id bigint NOT NULL
  - period_id bigint NOT NULL
  - total_amt real

## order_items (13 cols)
  - number character varying
  - quantity integer
  - cost integer
  - amount integer
  - order_id uuid
  - id integer NOT NULL
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - datetime timestamp without time zone
  - config_id integer
  - user_id integer
  - reward character varying
  - is_paid boolean

## orders (9 cols)
  - type character varying
  - id uuid NOT NULL
  - is_active boolean
  - state character varying
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - description character varying
  - user_id integer
  - expired_at timestamp without time zone

## reward_items (9 cols)
  - id integer NOT NULL
  - description character varying NOT NULL
  - number character varying NOT NULL
  - total_reward integer NOT NULL
  - description_th character varying
  - is_claim boolean
  - order_item_id integer NOT NULL
  - created_at timestamp without time zone
  - updated_at timestamp without time zone

## schema_migrations (2 cols)
  - version bigint NOT NULL
  - dirty boolean NOT NULL

## thai_lottery_configuration (10 cols)
  - version character varying
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - open_at timestamp without time zone
  - close_at timestamp without time zone
  - id integer NOT NULL
  - running_number integer
  - years integer
  - name character varying
  - cost integer

## transactions (13 cols)
  - txn_ref uuid NOT NULL
  - amount numeric NOT NULL
  - currency character varying NOT NULL
  - date_time timestamp without time zone NOT NULL
  - status character varying NOT NULL
  - sof_type character varying NOT NULL
  - account_id integer NOT NULL
  - type character varying NOT NULL
  - payment_method character varying NOT NULL
  - approval character varying
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - deleted_at timestamp without time zone

## user_invite (4 cols)
  - user_id integer
  - invite_link character varying
  - credit_usage integer
  - redeem boolean

## users (11 cols)
  - email character varying
  - password character varying
  - uuid uuid
  - mobile_number character varying NOT NULL
  - id integer NOT NULL
  - created_at timestamp without time zone
  - updated_at timestamp without time zone
  - deleted_at timestamp without time zone
  - is_active boolean
  - username character varying NOT NULL
  - invite_link character varying

## UNIQUE / settlement / idempotency indexes
  - account_balance :: account_balance_bank_code_idx :: USING btree (bank_code, bank_name, account_number)
  - account_balance :: account_balance_pk :: USING btree (id)
  - account_balance :: account_balance_un :: USING btree (user_id)
  - admin :: admin_pk :: USING btree (id)
  - admin :: admin_un :: USING btree (username)
  - batch_job_execution :: batch_job_execution_pkey :: USING btree (job_execution_id)
  - batch_job_execution_context :: batch_job_execution_context_pkey :: USING btree (job_execution_id)
  - batch_job_instance :: batch_job_instance_pkey :: USING btree (job_instance_id)
  - batch_job_instance :: job_inst_un :: USING btree (job_name, job_key)
  - batch_step_execution :: batch_step_execution_pkey :: USING btree (step_execution_id)
  - batch_step_execution_context :: batch_step_execution_context_pkey :: USING btree (step_execution_id)
  - databasechangeloglock :: databasechangeloglock_pkey :: USING btree (id)
  - lotto_batch_run :: lotto_batch_run_pkey :: USING btree (id)
  - lotto_draw_prize_result :: idx_lotto_draw_prize_result_game_period_settle_status :: USING btree (game_id, period_id, settlement_status)
  - lotto_draw_prize_result :: idx_lotto_draw_prize_result_settlement_attempted_at :: USING btree (settlement_attempted_at)
  - lotto_draw_prize_result :: lotto_draw_prize_result_pkey :: USING btree (id)
  - lotto_draw_prize_result :: uk_lotto_draw_prize_result_idempotency_key :: USING btree (idempotency_key)
  - lotto_draw_prize_result :: uk_lotto_draw_prize_result_order_draw_version :: USING btree (n3_orders_id, draw_result_id, result_version)
  - lotto_draw_prize_result :: uk_lotto_draw_prize_result_wallet_settlement_id :: USING btree (wallet_settlement_id) WHERE (wallet_settlement_id IS NOT NULL)
  - lotto_draw_prize_result_item :: lotto_draw_prize_result_item_pkey :: USING btree (id)
  - lotto_draw_prize_result_item_bet :: lotto_draw_prize_result_item_bet_pkey :: USING btree (id)
  - lotto_draw_prize_result_item_bet :: uk_lotto_draw_prize_result_item_bet_result_bet_version :: USING btree (lotto_draw_prize_result_item_id, bet_id, result_version)
  - lotto_draw_result :: lotto_draw_result_pkey :: USING btree (id)
  - lotto_draw_result :: uk_lotto_draw_result_draw_date_type :: USING btree (draw_date, draw_type)
  - lotto_n3_game :: lotto_n3_game_pk :: USING btree (id)
  - lotto_n3_item_order :: lotto_n3_item_order_pkey :: USING btree (id)
  - lotto_n3_period :: lotto_n3_period_pk :: USING btree (id)
  - lotto_reward :: lotto_reward_id_idx :: USING btree (id)
  - lotto_reward :: lotto_reward_pk :: USING btree (id)
  - n3_order_items :: n3_order_items_pk :: USING btree (id)
  - n3_order_items_bet :: n3_order_items_bet_pk :: USING btree (id)
  - n3_orders :: n3_orders_pk :: USING btree (id)
  - order_items :: order_items_pk :: USING btree (id)
  - orders :: orders_id_idx :: USING btree (id)
  - orders :: orders_pk :: USING btree (id)
  - reward_items :: items_reward_pk :: USING btree (id)
  - schema_migrations :: schema_migrations_pkey :: USING btree (version)
  - thai_lottery_configuration :: thai_lottery_configuration_pk :: USING btree (id)
  - transactions :: transactions_pk :: USING btree (txn_ref)
  - user_invite :: user_invite_un :: USING btree (invite_link, user_id)
  - users :: users_pk :: USING btree (id)
  - users :: users_un :: USING btree (invite_link)
  - users :: users_username_idx :: USING btree (username)