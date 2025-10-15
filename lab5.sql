-- Serikkali Mereilim
-- 24B032024

-- PART 1: CHECK CONSTRAINTS

-- Task 1.1: Basic CHECK
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

-- Valid data
INSERT INTO employees VALUES (1, 'Alice', 'Smith', 25, 50000);
INSERT INTO employees VALUES (2, 'Bob', 'Jones', 45, 70000);

-- Invalid data (violates CHECK)
-- INSERT INTO employees VALUES (3, 'Charlie', 'Young', 17, 30000); -- age < 18
-- INSERT INTO employees VALUES (4, 'Dana', 'Brown', 30, -5000);   -- salary < 0

-- Task 1.2: Named CHECK
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- Valid data
INSERT INTO products_catalog VALUES (1, 'Phone', 800, 600);
INSERT INTO products_catalog VALUES (2, 'Laptop', 1200, 1000);

-- Invalid data
-- INSERT INTO products_catalog VALUES (3, 'TV', 0, 200);     -- regular_price = 0
-- INSERT INTO products_catalog VALUES (4, 'Mouse', 50, 60);  -- discount_price > regular_price

-- Task 1.3: Multiple Column CHECK
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

-- Valid
INSERT INTO bookings VALUES (1, '2025-05-01', '2025-05-05', 3);
INSERT INTO bookings VALUES (2, '2025-06-10', '2025-06-15', 2);

-- Invalid
-- INSERT INTO bookings VALUES (3, '2025-07-01', '2025-06-30', 2); -- check_out < check_in
-- INSERT INTO bookings VALUES (4, '2025-08-01', '2025-08-10', 12); -- num_guests > 10

-- PART 2: NOT NULL CONSTRAINTS

CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

-- Valid
INSERT INTO customers VALUES (1, 'alice@mail.com', '123456789', '2025-05-10');
INSERT INTO customers VALUES (2, 'bob@mail.com', NULL, '2025-05-11');

-- Invalid
-- INSERT INTO customers VALUES (3, NULL, '111222333', '2025-05-12'); -- email is NOT NULL

CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Valid
INSERT INTO inventory VALUES (1, 'Monitor', 10, 200, NOW());
INSERT INTO inventory VALUES (2, 'Keyboard', 5, 50, NOW());

-- Invalid
-- INSERT INTO inventory VALUES (3, 'Mouse', -2, 30, NOW()); -- quantity < 0

-- PART 3: UNIQUE CONSTRAINTS

CREATE TABLE users (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

-- Valid
INSERT INTO users VALUES (1, 'user1', 'user1@mail.com', NOW());
INSERT INTO users VALUES (2, 'user2', 'user2@mail.com', NOW());

-- Invalid
-- INSERT INTO users VALUES (3, 'user1', 'user3@mail.com', NOW()); -- duplicate username
-- INSERT INTO users VALUES (4, 'user4', 'user2@mail.com', NOW()); -- duplicate email

CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);

-- Valid
INSERT INTO course_enrollments VALUES (1, 1001, 'CS101', 'Fall2025');
-- Invalid
-- INSERT INTO course_enrollments VALUES (2, 1001, 'CS101', 'Fall2025'); -- duplicate combo

-- PART 4: PRIMARY KEY

CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES (1, 'HR', 'Atyrau');
INSERT INTO departments VALUES (2, 'IT', 'Astana');
INSERT INTO departments VALUES (3, 'Finance', 'Almaty');

-- Invalid
-- INSERT INTO departments VALUES (1, 'HR2', 'Aktau'); -- duplicate dept_id

CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- PART 5: FOREIGN KEYS
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Murat', 1, '2025-05-01');
-- Invalid
-- INSERT INTO employees_dept VALUES (2, 'Aigerim', 99, '2025-05-02'); -- dept_id does not exist

-- Library schema
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors,
    publisher_id INTEGER REFERENCES publishers,
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

-- PART 6: E-COMMERCE DATABASE

CREATE TABLE customers_ecom (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products_ecom (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers_ecom ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_ecom,
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price > 0)
);

-- Sample inserts
INSERT INTO customers_ecom (name, email, phone, registration_date)
VALUES ('Alice', 'alice@mail.com', '123456', '2025-05-01'),
    ('Bob', 'bob@mail.com', '987654', '2025-05-02');

INSERT INTO products_ecom (name, description, price, stock_quantity)
VALUES ('Laptop', 'Gaming laptop', 1200, 10),
    ('Mouse', 'Wireless mouse', 25, 50),
    ('Keyboard', 'Mechanical keyboard', 75, 30);

INSERT INTO orders (customer_id, order_date, total_amount, status)
VALUES (1, '2025-05-03', 1250, 'processing'),
    (2, '2025-05-04', 100, 'pending');

INSERT INTO order_details (order_id, product_id, quantity, unit_price)
VALUES (1, 1, 1, 1200),
    (1, 2, 2, 25),
    (2, 3, 1, 75);

-- Invalid (violates CHECK)
-- INSERT INTO order_details (order_id, product_id, quantity, unit_price)
-- VALUES (2, 2, -5, 20); -- quantity must be positive
