-- 1. Create database
CREATE DATABASE advanced_lab;

-- Switch to database
\c advanced_lab;

-- Create table: employees
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(50) DEFAULT 'Active'
);

-- Create table: departments
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id INTEGER
);

-- Create table: projects
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

-- 2. INSERT with column specification
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'Alice', 'Johnson', 'HR');

-- 3. INSERT with DEFAULT values (salary & status use defaults)
INSERT INTO employees (first_name, last_name, department, hire_date)
VALUES ('Bob', 'Smith', 'Finance', '2023-06-01');

-- 4. INSERT multiple rows in single statement
INSERT INTO departments (dept_name, budget, manager_id)
VALUES 
    ('HR', 200000, 1),
    ('Finance', 300000, 2),
    ('IT', 500000, 3);

-- 5. INSERT with expressions
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Charlie', 'Brown', 'IT', CURRENT_DATE, 50000 * 1.1);

-- 6. INSERT from SELECT into a temporary table
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- 7. UPDATE with arithmetic expressions (increase salary 10%)
UPDATE employees
SET salary = salary * 1.10;

-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- 10. UPDATE with DEFAULT
ALTER TABLE employees ALTER COLUMN department SET DEFAULT 'General'; -- ensure default exists
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery
UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.2
    FROM employees e
    WHERE e.department = d.dept_name
)
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.department = d.dept_name
);

-- 12. UPDATE multiple columns in single statement
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- 13. DELETE with simple WHERE condition
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000 
AND hire_date > '2023-01-01'
AND department IS NULL;

-- 15. DELETE with subquery
DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT d.dept_id
    FROM employees e
    JOIN departments d ON e.department = d.dept_name
    WHERE e.department IS NOT NULL
);

-- 16. DELETE with RETURNING clause
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, salary, department, hire_date)
VALUES ('Diana', 'Prince', NULL, NULL, CURRENT_DATE);

-- 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- 20. INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Ethan', 'Hunt', 'Operations', CURRENT_DATE, 75000)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. UPDATE with RETURNING
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- 23. Conditional INSERT (only if no duplicate name exists)
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
SELECT 'Frank', 'Castle', 'Security', CURRENT_DATE, 60000
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Frank' AND last_name = 'Castle'
);

-- 24. UPDATE with JOIN logic using subqueries
UPDATE employees e
SET salary = salary * 
    CASE 
        WHEN (SELECT budget FROM departments d WHERE d.dept_name = e.department) > 100000
        THEN 1.10
        ELSE 1.05
    END;

-- 25. Bulk operations
-- Insert 5 employees in one statement
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES
    ('George', 'Miller', 'Finance', CURRENT_DATE, 50000),
    ('Helen', 'Clark', 'Finance', CURRENT_DATE, 52000),
    ('Ian', 'Wright', 'IT', CURRENT_DATE, 55000),
    ('Jane', 'Doe', 'HR', CURRENT_DATE, 48000),
    ('Kevin', 'Lee', 'Sales', CURRENT_DATE, 53000);

-- Then update all their salaries by 10%
UPDATE employees
SET salary = salary * 1.10
WHERE last_name IN ('Miller','Clark','Wright','Doe','Lee');

-- 26. Data migration simulation
CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE 1=0; -- structure only

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

-- 27. Complex business logic
UPDATE projects
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
AND end_date IS NOT NULL;





