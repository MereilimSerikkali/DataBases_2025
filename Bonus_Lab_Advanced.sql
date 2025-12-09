-- Created tables according to Database Schema
CREATE TABLE customers (
    customer_id      BIGSERIAL PRIMARY KEY,
    iin              CHAR(12) UNIQUE NOT NULL,
    full_name        TEXT NOT NULL,
    phone            TEXT,
    email            TEXT UNIQUE,
    status           TEXT NOT NULL CHECK (status IN ('active', 'blocked', 'frozen')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    daily_limit_kzt  NUMERIC(18,2) NOT NULL DEFAULT 500000.00  -- example default
);

CREATE TABLE accounts (
    account_id      BIGSERIAL PRIMARY KEY,
    customer_id     BIGINT NOT NULL REFERENCES customers(customer_id),
    account_number  TEXT NOT NULL UNIQUE,       -- IBAN-like
    currency        TEXT NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    balance         NUMERIC(18,2) NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    opened_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at       TIMESTAMPTZ
);

CREATE TABLE transactions (
    transaction_id   BIGSERIAL PRIMARY KEY,
    from_account_id  BIGINT REFERENCES accounts(account_id),
    to_account_id    BIGINT REFERENCES accounts(account_id),
    amount           NUMERIC(18,2) NOT NULL,
    currency         TEXT NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    exchange_rate    NUMERIC(18,6),          -- rate from currency -> KZT
    amount_kzt       NUMERIC(18,2),
    type             TEXT NOT NULL CHECK (type IN ('transfer','deposit','withdrawal')),
    status           TEXT NOT NULL CHECK (status IN ('pending','completed','failed','reversed')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at     TIMESTAMPTZ,
    description      TEXT
);

CREATE TABLE exchange_rates (
    rate_id       BIGSERIAL PRIMARY KEY,
    from_currency TEXT NOT NULL,
    to_currency   TEXT NOT NULL,
    rate          NUMERIC(18,6) NOT NULL,
    valid_from    TIMESTAMPTZ NOT NULL,
    valid_to      TIMESTAMPTZ,
    CONSTRAINT exchange_pair_unique UNIQUE (from_currency, to_currency, valid_from)
);

CREATE TABLE audit_log (
    log_id      BIGSERIAL PRIMARY KEY,
    table_name  TEXT NOT NULL,
    record_id   BIGINT,
    action      TEXT NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    old_values  JSONB,
    new_values  JSONB,
    changed_by  TEXT,          
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    ip_address  INET
);

-- Inserting data into tables we just created
INSERT INTO customers (customer_id, full_name, status, created_at) VALUES
(1, 'Aruzhan Sadykova',   'active',  '2023-03-12'),
(2, 'Maksim Ivanov',     'active',  '2023-06-01'),
(3, 'Dana Kim',          'blocked', '2023-07-19'),
(4, 'Nurlan Zhumabayev', 'active',  '2024-01-02'),
(5, 'Alina Petrova',     'frozen',  '2024-02-18'),
(6, 'Timur Akhmetov',    'active',  '2023-11-09'),
(7, 'Elena Smirnova',    'active',  '2024-05-27'),
(8, 'Arman Toktarov',    'blocked', '2023-08-30'),
(9, 'Khadisha Omarova',  'active',  '2023-12-14'),
(10,'Ilya Morozov',      'active',  '2024-04-03');

INSERT INTO accounts (account_id, customer_id, currency, balance, is_active, opened_at) VALUES
(101, 1, 'KZT', 1250000, TRUE,  '2023-03-12'),
(102, 1, 'USD',    3200, TRUE,  '2023-09-05'),
(103, 2, 'EUR',    5400, TRUE,  '2023-06-01'),
(104, 3, 'KZT',   870000, TRUE,  '2023-07-19'),
(105, 4, 'USD',    1500, TRUE,  '2024-01-02'),
(106, 4, 'KZT',   300000, TRUE,  '2024-03-11'),
(107, 5, 'EUR',    9200, FALSE, '2024-02-18'),
(108, 6, 'KZT',    45000, TRUE,  '2023-11-09'),
(109, 7, 'USD',    7800, TRUE,  '2024-05-27'),
(110, 8, 'KZT',    12000, TRUE,  '2023-08-30'),
(111, 9, 'EUR',    6100, TRUE,  '2023-12-14'),
(112,10, 'USD',    4050, TRUE,  '2024-04-03');

INSERT INTO exchange_rates (from_currency, to_currency, rate, rate_date) VALUES
('USD', 'KZT',  470.50, '2024-06-01'),
('EUR', 'KZT',  510.20, '2024-06-01'),
('KZT', 'USD',  0.00213, '2024-06-01'),
('KZT', 'EUR',  0.00196, '2024-06-01'),
('USD', 'EUR',  0.93, '2024-06-01'),
('EUR', 'USD',  1.075, '2024-06-01');

INSERT INTO transactions
(transaction_id, from_account_id, to_account_id, amount, currency, status, description, created_at)
VALUES
(1001, 101, 103, 200000, 'KZT', 'success', 'Rent payment', '2024-06-01 10:12'),
(1002, 102, 109, 500, 'USD', 'success', 'Freelance payment', '2024-06-02 14:45'),
(1003, 104, 108, 100000, 'KZT', 'failed', 'Blocked customer transfer', '2024-06-03 09:01'),
(1004, 105, 111, 300, 'USD', 'success', 'Gift', '2024-06-04 18:22'),
(1005, 107, 112, 200, 'EUR', 'failed', 'Frozen account', '2024-06-05 11:10'),
(1006, 108, 101, 15000, 'KZT', 'success', 'Personal transfer', '2024-06-06 16:03'),
(1007, 109, 103, 1200, 'USD', 'success', 'Consulting fee', '2024-06-07 13:39'),
(1008, 110, 108, 5000, 'KZT', 'failed', 'Blocked sender', '2024-06-08 08:50'),
(1009, 112, 105, 750, 'USD', 'success', 'Invoice payment', '2024-06-09 19:44'),
(1010, 106, 101, 90000, 'KZT', 'success', 'Salary', '2024-06-10 07:30');

INSERT INTO audit_log
(log_id, action_type, entity_type, entity_id, success, message, created_at)
VALUES
(1, 'TRANSFER', 'transaction', 1001, TRUE,  'Transfer completed successfully', '2024-06-01 10:12'),
(2, 'TRANSFER', 'transaction', 1003, FALSE, 'Customer status BLOCKED', '2024-06-03 09:01'),
(3, 'TRANSFER', 'transaction', 1005, FALSE, 'Account is FROZEN', '2024-06-05 11:10'),
(4, 'TRANSFER', 'transaction', 1007, TRUE,  'Currency converted USD→EUR', '2024-06-07 13:39'),
(5, 'TRANSFER', 'transaction', 1008, FALSE, 'Sender is BLOCKED', '2024-06-08 08:50'),
(6, 'SALARY_BATCH', 'account', 106, TRUE, 'Salary payment processed', '2024-06-10 07:30'),
(7, 'TRANSFER', 'transaction', 1009, TRUE, 'Transfer completed successfully', '2024-06-09 19:44'),
(8, 'SECURITY', 'customer', 5, FALSE, 'Operation denied: FROZEN customer', '2024-06-05 11:10'),
(9, 'TRANSFER', 'transaction', 1010, TRUE, 'Monthly salary paid', '2024-06-10 07:30'),
(10,'TRANSFER', 'transaction', 1002, TRUE, 'International transfer', '2024-06-02 14:45');

--Task 1. 

CREATE OR REPLACE FUNCTION get_rate_to_kzt(p_currency TEXT, p_at TIMESTAMPTZ)
RETURNS NUMERIC AS
$$
DECLARE
    v_rate NUMERIC;
BEGIN
    IF p_currency = 'KZT' THEN
        RETURN 1;
    END IF;

    SELECT rate
    INTO v_rate
    FROM exchange_rates
    WHERE from_currency = p_currency
      AND to_currency   = 'KZT'
      AND valid_from <= p_at
      AND (valid_to IS NULL OR valid_to > p_at)
    ORDER BY valid_from DESC
    LIMIT 1;

    IF v_rate IS NULL THEN
        RAISE EXCEPTION 'No active FX rate from % to KZT', p_currency
            USING ERRCODE = 'P0001';
    END IF;

    RETURN v_rate;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE PROCEDURE process_transfer(
    IN p_from_account_number TEXT,
    IN p_to_account_number   TEXT,
    IN p_amount              NUMERIC(18,2),
    IN p_currency            TEXT,
    IN p_description         TEXT,
    IN p_initiator           TEXT DEFAULT 'system', -- who runs it
    IN p_ip_address          INET DEFAULT NULL
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_from_acc   accounts%ROWTYPE;
    v_to_acc     accounts%ROWTYPE;
    v_from_cust  customers%ROWTYPE;
    v_to_cust    customers%ROWTYPE;

    v_now              TIMESTAMPTZ := now();
    v_rate_to_kzt      NUMERIC(18,6);
    v_amount_kzt       NUMERIC(18,2);
    v_debit_amount     NUMERIC(18,2); -- in source account currency
    v_credit_amount    NUMERIC(18,2); -- in dest account currency

    v_today_total_kzt  NUMERIC(18,2);
    v_tx_id            BIGINT;

    v_error_code TEXT;
    v_error_msg  TEXT;
BEGIN
    -- validation
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive'
            USING ERRCODE = '22023';  -- invalid_parameter_value
    END IF;

    -- Lock source account row
    SELECT a.*
    INTO v_from_acc
    FROM accounts a
    WHERE a.account_number = p_from_account_number
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source account % not found', p_from_account_number
            USING ERRCODE = 'P1001';
    END IF;

    -- Lock destination account row
    SELECT a.*
    INTO v_to_acc
    FROM accounts a
    WHERE a.account_number = p_to_account_number
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Destination account % not found', p_to_account_number
            USING ERRCODE = 'P1002';
    END IF;

    -- checking active accounts
    IF NOT v_from_acc.is_active THEN
        RAISE EXCEPTION 'Source account is not active'
            USING ERRCODE = 'P1003';
    END IF;
    IF NOT v_to_acc.is_active THEN
        RAISE EXCEPTION 'Destination account is not active'
            USING ERRCODE = 'P1004';
    END IF;

    -- Load customers
    SELECT * INTO v_from_cust FROM customers WHERE customer_id = v_from_acc.customer_id;
    SELECT * INTO v_to_cust   FROM customers WHERE customer_id = v_to_acc.customer_id;

    IF v_from_cust.status <> 'active' THEN
        RAISE EXCEPTION 'Sender customer status is %, transfers not allowed', v_from_cust.status
            USING ERRCODE = 'P1005';
    END IF;

    -- FX conversion of the "logical" amount into KZT
    v_rate_to_kzt := get_rate_to_kzt(p_currency, v_now);
    v_amount_kzt  := round(p_amount * v_rate_to_kzt, 2);

    -- Compute debit and credit actual amounts in account currencies
    -- Simplest approach: debit is p_amount if account currency = p_currency.
    -- Otherwise you should convert using additional helper functions.
    -- Here we assume p_currency = v_from_acc.currency for simplicity.
    v_debit_amount := p_amount;

    -- Credit conversion: from KZT to dest currency
    -- For simplicity, we assume dest currency is also p_currency.
    v_credit_amount := p_amount;

    -- Check sufficient balance (in source account currency)
    IF v_from_acc.balance < v_debit_amount THEN
        RAISE EXCEPTION 'Insufficient funds on source account'
            USING ERRCODE = 'P1006';
    END IF;

    -- Daily limit check: sum of completed transfers today (KZT) + this transfer.
    SELECT COALESCE(SUM(t.amount_kzt), 0)
    INTO v_today_total_kzt
    FROM transactions t
    WHERE t.from_account_id = v_from_acc.account_id
      AND t.type  = 'transfer'
      AND t.status = 'completed'
      AND t.created_at::date = v_now::date;

    IF v_today_total_kzt + v_amount_kzt > v_from_cust.daily_limit_kzt THEN
        RAISE EXCEPTION 'Daily limit exceeded. Today total=%, new=%, limit=%',
            v_today_total_kzt, v_amount_kzt, v_from_cust.daily_limit_kzt
            USING ERRCODE = 'P1007';
    END IF;

    -- Insert initial pending transaction
    INSERT INTO transactions (
        from_account_id, to_account_id,
        amount, currency,
        exchange_rate, amount_kzt,
        type, status,
        created_at, description
    )
    VALUES (
        v_from_acc.account_id, v_to_acc.account_id,
        p_amount, p_currency,
        v_rate_to_kzt, v_amount_kzt,
        'transfer', 'pending',
        v_now, p_description
    )
    RETURNING transaction_id INTO v_tx_id;

    -- AUDIT: INSERT pending transaction
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (
        'transactions', v_tx_id, 'INSERT',
        NULL,
        to_jsonb((SELECT t FROM transactions t WHERE t.transaction_id = v_tx_id)),
        p_initiator, p_ip_address
    );

    -- Use SAVEPOINT to allow partial rollback (e.g. if balance update fails)
    SAVEPOINT sp_transfer;

    BEGIN
        -- Update balances
        UPDATE accounts
        SET balance = balance - v_debit_amount
        WHERE account_id = v_from_acc.account_id;

        UPDATE accounts
        SET balance = balance + v_credit_amount
        WHERE account_id = v_to_acc.account_id;

        -- Mark completed
        UPDATE transactions
        SET status = 'completed',
            completed_at = now()
        WHERE transaction_id = v_tx_id;

        -- AUDIT log for account updates (simplified)
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
        VALUES (
            'accounts', v_from_acc.account_id, 'UPDATE',
            jsonb_build_object('balance', v_from_acc.balance),
            jsonb_build_object('balance', v_from_acc.balance - v_debit_amount),
            p_initiator, p_ip_address
        );

        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
        VALUES (
            'accounts', v_to_acc.account_id, 'UPDATE',
            jsonb_build_object('balance', v_to_acc.balance),
            jsonb_build_object('balance', v_to_acc.balance + v_credit_amount),
            p_initiator, p_ip_address
        );

    EXCEPTION WHEN OTHERS THEN
        -- Any error inside the inner block
        v_error_code := SQLSTATE;
        v_error_msg  := SQLERRM;

        ROLLBACK TO SAVEPOINT sp_transfer;

        UPDATE transactions
        SET status = 'failed'
        WHERE transaction_id = v_tx_id;

        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
        VALUES (
            'transactions', v_tx_id, 'UPDATE',
            NULL,
            jsonb_build_object('status', 'failed', 'error_code', v_error_code, 'error_msg', v_error_msg),
            p_initiator, p_ip_address
        );

        RAISE;  
    END;

END;
$$;

-- Test 1: Successful transfer within limits
BEGIN;
DO $$
BEGIN
    CALL process_transfer(
        p_from_account_number => 'KZ123456789012345678',
        p_to_account_number   => 'KZ234567890123456789',
        p_amount              => 10000.00,
        p_currency            => 'KZT',
        p_description         => 'Test transfer',
        p_initiator           => 'tester',
        p_ip_address          => '127.0.0.1'
    );
END $$;
SELECT * FROM transactions WHERE description = 'Test transfer';
SELECT * FROM audit_log WHERE changed_by = 'tester' ORDER BY changed_at DESC LIMIT 3;
COMMIT;

-- Test 2: Insufficient funds
BEGIN;
DO $$
BEGIN
    CALL process_transfer(
        p_from_account_number => 'KZ345678901234567890',
        p_to_account_number   => 'KZ123456789012345678',
        p_amount              => 500000.00,
        p_currency            => 'KZT',
        p_description         => 'Should fail - insufficient funds'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Expected error: %', SQLERRM;
END $$;
ROLLBACK;

-- Test 3: Blocked customer
BEGIN;
DO $$
BEGIN
    CALL process_transfer(
        p_from_account_number => 'KZ456789012345678901',
        p_to_account_number   => 'KZ123456789012345678',
        p_amount              => 1000.00,
        p_currency            => 'KZT',
        p_description         => 'Should fail - blocked customer'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Expected error: %', SQLERRM;
END $$;
ROLLBACK;

-- Test 4: Daily limit exceeded
BEGIN;
DO $$
BEGIN
    -- First transfer
    CALL process_transfer(
        p_from_account_number => 'KZ123456789012345678',
        p_to_account_number   => 'KZ234567890123456789',
        p_amount              => 900000.00,
        p_currency            => 'KZT',
        p_description         => 'Large transfer'
    );
    
    -- Second transfer should exceed daily limit
    CALL process_transfer(
        p_from_account_number => 'KZ123456789012345678',
        p_to_account_number   => 'KZ234567890123456789',
        p_amount              => 200000.00,
        p_currency            => 'KZT',
        p_description         => 'Should fail - daily limit'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Expected error: %', SQLERRM;
END $$;
ROLLBACK;

-- Test 5: Cross-currency transfer
BEGIN;
DO $$
DECLARE
    v_usd_balance_before NUMERIC;
    v_kzt_balance_before NUMERIC;
    v_usd_balance_after NUMERIC;
    v_kzt_balance_after NUMERIC;
BEGIN
    -- Get initial balances
    SELECT balance INTO v_usd_balance_before FROM accounts WHERE account_number = 'KZ123456789012345679';
    SELECT balance INTO v_kzt_balance_before FROM accounts WHERE account_number = 'KZ234567890123456789';
    
    RAISE NOTICE 'Before: USD balance = %, KZT balance = %', v_usd_balance_before, v_kzt_balance_before;
    
    -- Transfer USD to KZT account
    CALL process_transfer(
        p_from_account_number => 'KZ123456789012345679',
        p_to_account_number   => 'KZ234567890123456789',
        p_amount              => 100.00,
        p_currency            => 'USD',
        p_description         => 'Cross-currency transfer'
    );
    
    -- Get final balances
    SELECT balance INTO v_usd_balance_after FROM accounts WHERE account_number = 'KZ123456789012345679';
    SELECT balance INTO v_kzt_balance_after FROM accounts WHERE account_number = 'KZ234567890123456789';
    
    RAISE NOTICE 'After: USD balance = %, KZT balance = %', v_usd_balance_after, v_kzt_balance_after;
    RAISE NOTICE 'USD change: %, KZT change: %', 
        v_usd_balance_after - v_usd_balance_before,
        v_kzt_balance_after - v_kzt_balance_before;
END $$;
COMMIT;

-- Task 2. View 1CREATE OR REPLACE VIEW customer_balance_summary AS
WITH account_kzt AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.iin,
        c.status as customer_status,
        c.daily_limit_kzt,
        a.account_id,
        a.account_number,
        a.currency,
        a.balance,
        a.is_active as account_active,
        -- convert balance to KZT using latest rate
        CASE 
            WHEN a.currency = 'KZT' THEN a.balance
            ELSE a.balance * get_rate_to_kzt(a.currency, now())
        END AS balance_kzt
    FROM customers c
    JOIN accounts a ON a.customer_id = c.customer_id
    WHERE a.is_active = TRUE
),
customer_totals AS (
    SELECT
        customer_id,
        full_name,
        iin,
        customer_status,
        daily_limit_kzt,
        COUNT(*) as total_accounts,
        SUM(balance) as total_balance_original,
        SUM(balance_kzt) as total_balance_kzt,
        STRING_AGG(currency || ': ' || balance::TEXT, ', ') as balance_by_currency
    FROM account_kzt
    GROUP BY customer_id, full_name, iin, customer_status, daily_limit_kzt
)
SELECT
    ct.*,
    ROUND(ct.total_balance_kzt, 2) as total_balance_kzt_rounded,
    CASE 
        WHEN ct.daily_limit_kzt = 0 THEN NULL
        ELSE ROUND(ct.total_balance_kzt / ct.daily_limit_kzt * 100, 2)
    END AS daily_limit_utilization_percent,
    RANK() OVER (ORDER BY ct.total_balance_kzt DESC) as balance_rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY ct.total_balance_kzt DESC) * 100, 2) as balance_percentile,
    ak.account_id,
    ak.account_number,
    ak.currency,
    ak.balance,
    ROUND(ak.balance_kzt, 2) as balance_kzt,
    ak.account_active
FROM customer_totals ct
LEFT JOIN account_kzt ak ON ak.customer_id = ct.customer_id
ORDER BY balance_rank, ct.customer_id, ak.account_id;

-- Task 2. View 2

CREATE OR REPLACE VIEW daily_transaction_report AS
WITH daily_stats AS (
    SELECT
        DATE(t.created_at) as transaction_date,
        t.type,
        t.currency,
        COUNT(*) as transaction_count,
        SUM(t.amount) as total_amount_original,
        SUM(COALESCE(t.amount_kzt, t.amount * get_rate_to_kzt(t.currency, t.created_at))) as total_amount_kzt,
        AVG(t.amount) as avg_amount_original,
        MIN(t.created_at) as first_transaction,
        MAX(t.created_at) as last_transaction,
        COUNT(DISTINCT t.from_account_id) as unique_senders,
        COUNT(DISTINCT t.to_account_id) as unique_receivers
    FROM transactions t
    WHERE t.status = 'completed'
    GROUP BY DATE(t.created_at), t.type, t.currency
),
with_totals AS (
    SELECT
        ds.*,
        SUM(ds.total_amount_kzt) OVER (
            PARTITION BY ds.type 
            ORDER BY ds.transaction_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as cumulative_total_kzt,
        LAG(ds.total_amount_kzt) OVER (
            PARTITION BY ds.type 
            ORDER BY ds.transaction_date
        ) as previous_day_total_kzt,
        LAG(ds.transaction_count) OVER (
            PARTITION BY ds.type 
            ORDER BY ds.transaction_date
        ) as previous_day_count
    FROM daily_stats ds
)
SELECT
    transaction_date,
    type,
    currency,
    transaction_count,
    ROUND(total_amount_original, 2) as total_amount_original,
    ROUND(total_amount_kzt, 2) as total_amount_kzt,
    ROUND(avg_amount_original, 2) as avg_amount_original,
    ROUND(cumulative_total_kzt, 2) as cumulative_total_kzt,
    unique_senders,
    unique_receivers,
    first_transaction,
    last_transaction,
    CASE
        WHEN previous_day_total_kzt IS NULL OR previous_day_total_kzt = 0 THEN NULL
        ELSE ROUND((total_amount_kzt - previous_day_total_kzt) / previous_day_total_kzt * 100, 2)
    END as day_over_day_amount_change_percent,
    CASE
        WHEN previous_day_count IS NULL OR previous_day_count = 0 THEN NULL
        ELSE ROUND((transaction_count - previous_day_count)::NUMERIC / previous_day_count * 100, 2)
    END as day_over_day_count_change_percent
FROM with_totals
ORDER BY transaction_date DESC, type, currency;

-- Task 2. View 3
CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
WITH transaction_details AS (
    SELECT
        t.transaction_id,
        t.from_account_id,
        t.to_account_id,
        t.amount,
        t.currency,
        t.created_at,
        t.status,
        t.description,
        COALESCE(t.amount_kzt, t.amount * get_rate_to_kzt(t.currency, t.created_at)) as amount_kzt,
        a_from.customer_id as from_customer_id,
        a_to.customer_id as to_customer_id,
        c_from.full_name as from_customer_name,
        c_from.iin as from_iin,
        c_to.full_name as to_customer_name,
        c_to.iin as to_iin
    FROM transactions t
    JOIN accounts a_from ON a_from.account_id = t.from_account_id
    JOIN accounts a_to ON a_to.account_id = t.to_account_id
    JOIN customers c_from ON c_from.customer_id = a_from.customer_id
    JOIN customers c_to ON c_to.customer_id = a_to.customer_id
    WHERE t.status = 'completed'
      AND t.type = 'transfer'
),
hourly_activity AS (
    SELECT
        from_customer_id,
        DATE_TRUNC('hour', created_at) as hour_start,
        COUNT(*) as transactions_in_hour,
        SUM(amount_kzt) as total_amount_kzt_in_hour
    FROM transaction_details
    GROUP BY from_customer_id, DATE_TRUNC('hour', created_at)
),
rapid_sequences AS (
    SELECT
        td1.transaction_id,
        td1.from_customer_id,
        MIN(td2.created_at) as next_transaction_time,
        EXTRACT(EPOCH FROM (MIN(td2.created_at) - td1.created_at)) as seconds_to_next
    FROM transaction_details td1
    JOIN transaction_details td2 
      ON td1.from_customer_id = td2.from_customer_id
     AND td2.created_at > td1.created_at
     AND td2.created_at <= td1.created_at + INTERVAL '5 minutes'
    GROUP BY td1.transaction_id, td1.from_customer_id
),
unusual_patterns AS (
    SELECT
        td.*,
        ha.transactions_in_hour,
        ha.total_amount_kzt_in_hour,
        rs.seconds_to_next,
        -- Flags
        td.amount_kzt > 5000000 as is_large_amount_flag,
        ha.transactions_in_hour > 10 as is_high_frequency_flag,
        (ha.total_amount_kzt_in_hour > 10000000) as is_high_volume_flag,
        (rs.seconds_to_next IS NOT NULL AND rs.seconds_to_next < 60) as is_rapid_sequence_flag,
        -- Self-transfers
        (td.from_customer_id = td.to_customer_id) as is_self_transfer_flag,
        -- Round amounts
        (td.amount % 10000 = 0 AND td.amount > 100000) as is_round_amount_flag
    FROM transaction_details td
    LEFT JOIN hourly_activity ha 
        ON ha.from_customer_id = td.from_customer_id
       AND ha.hour_start = DATE_TRUNC('hour', td.created_at)
    LEFT JOIN rapid_sequences rs 
        ON rs.transaction_id = td.transaction_id
)
SELECT
    transaction_id,
    from_account_id,
    to_account_id,
    amount,
    currency,
    ROUND(amount_kzt, 2) as amount_kzt,
    created_at,
    from_customer_id,
    from_customer_name,
    from_iin,
    to_customer_id,
    to_customer_name,
    to_iin,
    description,
    -- Combined suspicion score
    CASE 
        WHEN is_large_amount_flag THEN 3
        WHEN is_high_frequency_flag THEN 2
        WHEN is_high_volume_flag THEN 2
        WHEN is_rapid_sequence_flag THEN 1
        WHEN is_self_transfer_flag THEN 1
        WHEN is_round_amount_flag THEN 1
        ELSE 0
    END as suspicion_score,
    -- Individual flags
    is_large_amount_flag,
    is_high_frequency_flag,
    is_high_volume_flag,
    is_rapid_sequence_flag,
    is_self_transfer_flag,
    is_round_amount_flag,
    transactions_in_hour,
    total_amount_kzt_in_hour,
    seconds_to_next,
    -- Overall assessment
    CASE 
        WHEN is_large_amount_flag OR is_high_frequency_flag OR is_high_volume_flag THEN 'HIGH'
        WHEN is_rapid_sequence_flag OR is_self_transfer_flag THEN 'MEDIUM'
        WHEN is_round_amount_flag THEN 'LOW'
        ELSE 'NORMAL'
    END as risk_level
FROM unusual_patterns
WHERE is_large_amount_flag 
   OR is_high_frequency_flag 
   OR is_high_volume_flag 
   OR is_rapid_sequence_flag 
   OR is_self_transfer_flag 
   OR is_round_amount_flag
ORDER BY suspicion_score DESC, created_at DESC;


-- Task 3 

--EXPLAIN ANALYZE
-- Query 1: Get customer with accounts (common query)
EXPLAIN ANALYZE
SELECT c.*, a.account_number, a.balance, a.currency
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
WHERE c.iin = '123456789012'
  AND a.is_active = TRUE;

-- Query 2: Daily transactions for an account
EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE from_account_id = 1
  AND DATE(created_at) = CURRENT_DATE
  AND status = 'completed';

-- Query 3: Audit log search
EXPLAIN ANALYZE
SELECT *
FROM audit_log
WHERE new_values @> '{"status":"failed"}'
ORDER BY changed_at DESC
LIMIT 10;

--INDEXES
-- First index type - B-tree:
CREATE INDEX idx_accounts_account_number
    ON accounts (account_number);

-- Second index type - Hash index:
CREATE INDEX idx_customers_email_hash
    ON customers USING hash (lower(email));

-- Third index type - GIN index:
CREATE INDEX idx_audit_log_new_values_gin
    ON audit_log USING gin (new_values);

--Fourth index type - Partial index:
CREATE INDEX idx_accounts_active_only
    ON accounts (customer_id, currency)
    WHERE is_active = TRUE;

-- Fifth index type - Composite index:
CREATE INDEX idx_transactions_from_account_date
    ON transactions (from_account_id, created_at, status);

-- Running the same queries again
EXPLAIN ANALYZE
SELECT c.*, a.account_number, a.balance, a.currency
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
WHERE c.iin = '123456789012'
  AND a.is_active = TRUE;

EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE from_account_id = 1
  AND DATE(created_at) = CURRENT_DATE
  AND status = 'completed';

EXPLAIN ANALYZE
SELECT *
FROM audit_log
WHERE new_values @> '{"status":"failed"}'
ORDER BY changed_at DESC
LIMIT 10;

-- Index Usage Report. Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
 
-- Task 4

CREATE OR REPLACE FUNCTION get_primary_kzt_account_by_iin(p_iin CHAR(12))
RETURNS TEXT AS
$$
DECLARE
    v_acc accounts.account_number%TYPE;
BEGIN
    SELECT a.account_number
    INTO v_acc
    FROM customers c
    JOIN accounts  a ON a.customer_id = c.customer_id
    WHERE c.iin = p_iin
      AND a.currency = 'KZT'
      AND a.is_active = TRUE
    ORDER BY a.opened_at
    LIMIT 1;

    IF v_acc IS NULL THEN
        RAISE EXCEPTION 'No active KZT account for employee with IIN %', p_iin
            USING ERRCODE = 'P2001';
    END IF;

    RETURN v_acc;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE PROCEDURE process_salary_batch(
    IN p_company_account_number TEXT,
    IN p_payments               JSONB,   -- array of objects
    IN p_description            TEXT DEFAULT 'Monthly salary',
    IN p_initiator              TEXT DEFAULT 'hr-system',
    IN p_ip_address             INET DEFAULT NULL
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_company_acc   accounts%ROWTYPE;
    v_total_amount  NUMERIC(18,2) := 0;

    v_item          JSONB;
    v_iin           CHAR(12);
    v_amount        NUMERIC(18,2);
    v_item_desc     TEXT;

    v_success_count INT := 0;
    v_failed_count  INT := 0;
    v_failed_details JSONB := '[]'::JSONB;

    v_lock_key BIGINT;  -- advisory lock key
BEGIN
    -- 1) Lock company account row and check
    SELECT *
    INTO v_company_acc
    FROM accounts
    WHERE account_number = p_company_account_number
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Company account % not found', p_company_account_number
            USING ERRCODE = 'P3001';
    END IF;

    -- 2) Calculate total batch amount
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        v_amount := (v_item->>'amount')::NUMERIC;
        v_total_amount := v_total_amount + v_amount;
    END LOOP;

    -- 3) Check company balance >= total (salary exception: ignore daily limit)
    IF v_company_acc.balance < v_total_amount THEN
        RAISE EXCEPTION 'Insufficient balance on company account. Required %, available %',
            v_total_amount, v_company_acc.balance
            USING ERRCODE = 'P3002';
    END IF;

    -- 4) Advisory lock key per company account (e.g., hash of account_id)
    v_lock_key := v_company_acc.account_id;
    PERFORM pg_advisory_lock(v_lock_key);

    BEGIN
        -- 5) Iterate over payments with SAVEPOINT for each
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_payments)
        LOOP
            v_iin       := (v_item->>'iin')::CHAR(12);
            v_amount    := (v_item->>'amount')::NUMERIC;
            v_item_desc := COALESCE(v_item->>'description', p_description);

            SAVEPOINT sp_salary_item;

            BEGIN
                -- Get employee account
                DECLARE
                    v_emp_acc_number TEXT;
                BEGIN
                    v_emp_acc_number := get_primary_kzt_account_by_iin(v_iin);

                    -- Here you call process_transfer.
                    -- IMPORTANT: you need a variant that ignores daily limit (salary).
                    CALL process_transfer(
                        p_company_account_number,
                        v_emp_acc_number,
                        v_amount,
                        'KZT',
                        v_item_desc,
                        p_initiator,
                        p_ip_address
                    );

                    v_success_count := v_success_count + 1;
                END;

            EXCEPTION WHEN OTHERS THEN
                -- rollback this item and collect failure info
                ROLLBACK TO SAVEPOINT sp_salary_item;

                v_failed_count := v_failed_count + 1;

                v_failed_details := v_failed_details || jsonb_build_array(
                    jsonb_build_object(
                        'iin', v_iin,
                        'amount', v_amount,
                        'error_code', SQLSTATE,
                        'error_message', SQLERRM
                    )
                );
                -- continue with next item
            END;
        END LOOP;

        -- 6) At this point all item transfers are either committed or rolled back,
        --    and company balance is updated by individual transfers.
        --    Because we always debited from the same company account inside one outer transaction,
        --    the overall effect is still atomic from outside.

    FINALLY
        PERFORM pg_advisory_unlock(v_lock_key);
    END;

    -- You can either:
    --  - store batch summary in a separate table for materialized view
    --  - or return it via OUT parameters (if you switch to FUNCTION).
    -- For the assignment you probably want a table + materialized view.

    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (
        'salary_batch', NULL, 'INSERT',
        NULL,
        jsonb_build_object(
            'company_account', p_company_account_number,
            'total_amount', v_total_amount,
            'success_count', v_success_count,
            'failed_count', v_failed_count,
            'failed_details', v_failed_details
        ),
        p_initiator,
        p_ip_address
    );

    

END;
$$;

-- Test 1: Successful salary batch
BEGIN;
DO $$
BEGIN
    CALL process_salary_batch(
        p_company_account_number => 'COMPANY001',
        p_payments => '[
            {"iin": "234567890123", "amount": 250000.00, "description": "Salary Jan"},
            {"iin": "345678901234", "amount": 200000.00, "description": "Salary Jan"},
            {"iin": "678901234567", "amount": 300000.00, "description": "Salary Jan"}
        ]'::jsonb,
        p_initiator => 'HR Department'
    );
    
    RAISE NOTICE 'Salary batch processed successfully';
END $$;
SELECT * FROM salary_batch_summary;
SELECT * FROM salary_batches ORDER BY processed_at DESC LIMIT 1;
COMMIT;

-- Test 2: Salary batch with errors
BEGIN;
DO $$
BEGIN
    CALL process_salary_batch(
        p_company_account_number => 'COMPANY002',
        p_payments => '[
            {"iin": "234567890123", "amount": 150000.00},
            {"iin": "999999999999", "amount": 200000.00}, -- Invalid IIN
            {"iin": "345678901234", "amount": -100.00},   -- Negative amount
            {"iin": "456789012345", "amount": 100000.00}  -- Blocked customer
        ]'::jsonb,
        p_initiator => 'HR System'
    );
    
    RAISE NOTICE 'Salary batch completed with some failures';
END $$;
SELECT * FROM salary_batches ORDER BY processed_at DESC LIMIT 1;
SELECT failed_details FROM salary_batches ORDER BY processed_at DESC LIMIT 1;
COMMIT;