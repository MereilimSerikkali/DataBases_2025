--table 
CREATE TABLE accounts (
 id SERIAL PRIMARY KEY,
 name VARCHAR(100) NOT NULL,
 balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
 id SERIAL PRIMARY KEY,
 shop VARCHAR(100) NOT NULL,
 product VARCHAR(100) NOT NULL,
 price DECIMAL(10, 2) NOT NULL
);
-- Insert test data
INSERT INTO accounts (name, balance) VALUES
 ('Alice', 1000.00),
 ('Bob', 500.00),
 ('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
Level Description Phenomena Allowed
SERIALIZABLE Highest isolation. Transactions appear to
execute serially. None
REPEATABLE
READ
Data read is guaranteed to be the same if read
again. Phantom reads
READ
COMMITTED
Only sees committed data, but may see
different data on re-read.
Non-repeatable reads,
Phantoms
READ
UNCOMMITTED
Can see uncommitted changes from other
transactions.
Dirty reads, Non-repeatable,
Phantoms
 ('Joe''s Shop', 'Coke', 2.50),
 ('Joe''s Shop', 'Pepsi', 3.00);
-- 3.2 
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
COMMIT;

-- 3.3 
BEGIN;
UPDATE accounts SET balance = balance - 500.00 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';

-- 3.4 
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';
COMMIT;

-- 3.5 
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;


-- Terminal 1
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- 3.6
-- Terminal 1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- Terminal 2
BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;

-- 3.7 
-- Terminal 1
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- Terminal 2
BEGIN;
UPDATE products SET price = 99.99 WHERE product = 'Fanta';
ROLLBACK;

-- 4.1
DO $$
BEGIN
    IF (SELECT balance FROM accounts WHERE name = 'Bob') >= 200 THEN
        BEGIN;
        UPDATE accounts SET balance = balance - 200 WHERE name = 'Bob';
        UPDATE accounts SET balance = balance + 200 WHERE name = 'Wally';
        COMMIT;
    ELSE
        RAISE NOTICE 'Insufficient funds';
    END IF;
END $$;

-- 4.2
BEGIN;
INSERT INTO products (shop, product, price) VALUES ('New Shop', 'New Product', 10.00);
SAVEPOINT sp1;
UPDATE products SET price = 15.00 WHERE product = 'New Product';
SAVEPOINT sp2;
DELETE FROM products WHERE product = 'New Product';
ROLLBACK TO sp1;
COMMIT;

--4.3
-- Session 1
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts SET balance = balance - 50 WHERE name = 'Alice';
COMMIT;

-- Session 2
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts SET balance = balance - 30 WHERE name = 'Alice';
COMMIT;

-- 4.4
-- Without transactions (problem scenario)
-- Session 1 (Joe)
UPDATE Sells SET price = price * 1.1 WHERE shop = 'Joe''s Shop';
-- Session 2 (Sally) runs concurrently
SELECT MAX(price), MIN(price) FROM Sells WHERE shop = 'Joe''s Shop';

-- With transactions (solution)
-- Session 1 (Joe)
BEGIN;
UPDATE Sells SET price = price * 1.1 WHERE shop = 'Joe''s Shop';
COMMIT;

-- Session 2 (Sally)
BEGIN;
SELECT MAX(price), MIN(price) FROM Sells WHERE shop = 'Joe''s Shop';
COMMIT;
 /*
1. 
- Atomicity: All operations in a transaction succeed or none do. Example: A bank transfer deducts $100 from Alice and adds $100 to Bob. If Bob’s update fails, Alice’s deduction is rolled back.  
- Consistency: Transactions keep the database in a valid state. Example: A CHECK constraint ensures balance ≥ 0; a transaction cannot violate it.  
- Isolation: Concurrent transactions do not interfere. Example: Two users withdrawing from the same account see consistent balances.  
- Durability: Once committed, changes survive crashes. Example: After a transfer is confirmed, a power outage won’t revert it.

2. 
- COMMIT makes all changes in a transaction permanent.  
- ROLLBACK undoes all changes in a transaction, reverting to the state before the transaction began.

3. 
SAVEPOINT is used to roll back part of a transaction while keeping earlier changes. Example: In a multi-step process, if step 3 fails, you can roll back to step 2 without losing steps 1–2.

4.
- READ UNCOMMITTED: Allows dirty reads, non-repeatable reads, phantoms. Lowest isolation.  
- READ COMMITTED: Prevents dirty reads; allows non-repeatable reads and phantoms. Default in many DBMS.  
- REPEATABLE READ: Prevents dirty reads and non-repeatable reads; allows phantoms.  
- SERIALIZABLE: Prevents all phenomena; highest isolation. Transactions appear to run sequentially.

5. 
A dirty read occurs when a transaction reads uncommitted data from another transaction. **READ UNCOMMITTED** allows dirty reads.

6.
A non-repeatable read occurs when a transaction reads the same row twice and gets different data because another transaction modified it between reads. Example: User A reads Bob’s balance as $500; User B updates it to $400 and commits; User A reads again and sees $400.

7.
A phantom read occurs when a transaction re-executes a query and gets more rows because another transaction inserted matching rows. **SERIALIZABLE** prevents it; **REPEATABLE READ** allows it.

8. 
READ COMMITTED has lower locking overhead and allows more concurrency, reducing contention and improving performance in high-traffic systems.

9.
Transactions isolate operations so intermediate states are not visible to other transactions. Locking and MVCC (Multi-Version Concurrency Control) ensure that concurrent transactions see consistent snapshots of data.

10. 
Uncommitted changes are **rolled back** automatically upon recovery due to the **Atomicity** property of ACID. The database restores the state before the transaction started.
 */

 --CONCLUSION
/*
During this lab, I learned that **transactions** are essential for grouping SQL operations into a single reliable unit, ensuring that all steps either complete successfully or none at all. I practiced using **COMMIT**
to save changes and **ROLLBACK** to undo them, which helps maintain data integrity when errors occur. By working with **SAVEPOINT**, I saw how I can roll back only part of a transaction, which is useful in complex multi-step
processes. I also explored different **isolation levels** and saw firsthand how they control what data one transaction can see while another is still running, balancing between consistency and performance. Overall, this lab 
showed me how transactions protect data in real-world applications like banking, especially when many users are accessing the database at the same time.
*/