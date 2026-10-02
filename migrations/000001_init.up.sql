--
--
-- Name: account_balance; Type: TABLE; Schema: public; Owner: chayakorn.kaewwong
--

CREATE TABLE  account_balance (
    id serial PRIMARY KEY,
    bank_code character varying NOT NULL,
    bank_name character varying NOT NULL,
    account_number character varying NOT NULL,
    balance integer DEFAULT 0,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    account_name character varying NOT NULL
);



--
-- Name: admin; Type: TABLE; Schema: public; Owner: chayakorn.kaewwong
--

CREATE TABLE admins (
    id uuid NOT NULL,
    username character varying,
    password character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);




CREATE TABLE order_items (
    number character varying,
    quantity integer,
    cost integer,
    amount integer,
    order_id uuid,
    id serial PRIMARY KEY,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    datetime timestamp without time zone,
    config_id integer,
    user_id integer,
    reward character varying,
    is_paid boolean
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: chayakorn.kaewwong
--

CREATE TABLE orders (
    type character varying,
    id uuid NOT NULL,
    is_active boolean,
    state character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description character varying,
    user_id integer,
    expired_at timestamp without time zone
);

CREATE TABLE thai_lottery_configuration (
    version character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    open_at timestamp without time zone,
    close_at timestamp without time zone,
    id serial PRIMARY KEY,
    running_number integer,
    years integer,
    name character varying,
    cost integer,
    assets_name character varying
);

CREATE TABLE transactions (
    txn_ref uuid NOT NULL,
    amount numeric NOT NULL,
    currency character varying NOT NULL,
    date_time timestamp without time zone NOT NULL,
    status character varying NOT NULL,
    sof_type character varying NOT NULL,
    account_id integer NOT NULL,
    type character varying NOT NULL,
    payment_method character varying NOT NULL,
    approval character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);



CREATE TABLE users (
    email character varying,
    password character varying,
    uuid uuid,
    mobile_number character varying NOT NULL,
    id serial PRIMARY KEY,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    is_active boolean,
    username character varying NOT NULL,
    invite_link character varying
);






--
-- Name: account_balance account_balance_un; Type: CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

ALTER TABLE ONLY account_balance
    ADD CONSTRAINT account_balance_un UNIQUE (user_id);


--
-- Name: admin admin_pk; Type: CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

-- ALTER TABLE ONLY admin
--     ADD CONSTRAINT admin_pk PRIMARY KEY (id);


--
-- Name: admin admin_un; Type: CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admin_un UNIQUE (username);


--
-- Name: order_items order_items_pk; Type: CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

-- ALTER TABLE ONLY public.order_items
--     ADD CONSTRAINT order_items_pk PRIMARY KEY (id);


--
-- Name: orders orders_pk; Type: CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

-- ALTER TABLE ONLY public.orders
--     ADD CONSTRAINT orders_pk PRIMARY KEY (id);


--
-- Name: transactions transactions_pk; Type: CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pk PRIMARY KEY (txn_ref);


--
-- Name: users users_pk; Type: CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

-- ALTER TABLE ONLY public.users
--     ADD CONSTRAINT users_pk PRIMARY KEY (id);


--
-- Name: users users_un; Type: CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

-- ALTER TABLE ONLY public.users
--     ADD CONSTRAINT users_un UNIQUE (id);


--
-- Name: account_balance_bank_code_idx; Type: INDEX; Schema: public; Owner: chayakorn.kaewwong
--

CREATE UNIQUE INDEX account_balance_bank_code_idx ON account_balance USING btree (bank_code, bank_name, account_number);


--
-- Name: admin_id_idx; Type: INDEX; Schema: public; Owner: chayakorn.kaewwong
--

CREATE INDEX admin_id_idx ON admins USING btree (id, username);


--
-- Name: orders_id_idx; Type: INDEX; Schema: public; Owner: chayakorn.kaewwong
--

CREATE UNIQUE INDEX orders_id_idx ON orders USING btree (id);


--
-- Name: users_id_idx; Type: INDEX; Schema: public; Owner: chayakorn.kaewwong
--

CREATE INDEX users_id_idx ON users USING btree (id);


--
-- Name: users_username_idx; Type: INDEX; Schema: public; Owner: chayakorn.kaewwong
--

CREATE UNIQUE INDEX users_username_idx ON users USING btree (username);


--
-- Name: account_balance account_balance_fk; Type: FK CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

ALTER TABLE ONLY account_balance
    ADD CONSTRAINT account_balance_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: order_items order_items_fk; Type: FK CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

ALTER TABLE ONLY order_items
    ADD CONSTRAINT order_items_fk FOREIGN KEY (order_id) REFERENCES public.orders(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: orders orders_fk; Type: FK CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: transactions transactions_fk; Type: FK CONSTRAINT; Schema: public; Owner: chayakorn.kaewwong
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_fk FOREIGN KEY (account_id) REFERENCES public.account_balance(id) ON UPDATE CASCADE ON DELETE CASCADE;

