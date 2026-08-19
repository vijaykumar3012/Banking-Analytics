-- =========================================================
-- Banking Customer & Transaction Analytics
-- MySQL Version
-- =========================================================

-- Step 1: Create Database
CREATE DATABASE IF NOT EXISTS banking_analytics_db;
USE banking_analytics_db;

-- Step 2: Customers Table
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS branches;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50),
    customer_segment VARCHAR(30),
    signup_date DATE
);

-- Step 3: Branches Table
CREATE TABLE branches (
    branch_id INT PRIMARY KEY,
    branch_name VARCHAR(100),
    city VARCHAR(50)
);

-- Step 4: Accounts Table
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    customer_id INT,
    branch_id INT,
    account_type VARCHAR(30),
    opening_date DATE,
    current_balance DECIMAL(15,2),
    account_status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- Step 5: Transactions Table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    account_id INT,
    transaction_date DATETIME,
    transaction_type VARCHAR(30),
    amount DECIMAL(15,2),
    transaction_status VARCHAR(20),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Step 6: Loans Table
CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    customer_id INT,
    loan_type VARCHAR(50),
    loan_amount DECIMAL(15,2),
    interest_rate DECIMAL(5,2),
    loan_status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Step 7: Insert Sample Customers
INSERT INTO customers VALUES
(1,'Rahul Sharma','Mumbai','Premium','2022-01-10'),
(2,'Priya Verma','Delhi','Mass Affluent','2022-04-15'),
(3,'Amit Patel','Pune','Premium','2023-02-20'),
(4,'Sneha Joshi','Bangalore','Mass Market','2023-06-05'),
(5,'Rohan Gupta','Hyderabad','Premium','2024-01-18');

-- Step 8: Insert Sample Branches
INSERT INTO branches VALUES
(101,'Mumbai Central','Mumbai'),
(102,'Connaught Place','Delhi'),
(103,'Pune Central','Pune'),
(104,'Bangalore Main','Bangalore');

-- Step 9: Insert Sample Accounts
INSERT INTO accounts VALUES
(1001,1,101,'Savings','2022-01-10',250000,'Active'),
(1002,2,102,'Current','2022-04-15',520000,'Active'),
(1003,3,103,'Savings','2023-02-20',175000,'Active'),
(1004,4,104,'Savings','2023-06-05',85000,'Active'),
(1005,5,101,'Current','2024-01-18',750000,'Active');

-- Step 10: Insert Sample Transactions
INSERT INTO transactions VALUES
(5001,1001,'2025-01-05 10:15:00','Deposit',50000,'Success'),
(5002,1001,'2025-01-07 14:30:00','Withdrawal',15000,'Success'),
(5003,1002,'2025-01-08 11:20:00','Deposit',120000,'Success'),
(5004,1003,'2025-01-10 09:45:00','Withdrawal',25000,'Success'),
(5005,1004,'2025-01-12 16:10:00','Deposit',30000,'Success'),
(5006,1005,'2025-01-15 13:25:00','Withdrawal',85000,'Success'),
(5007,1003,'2025-01-18 18:40:00','Transfer',45000,'Success');

-- Step 11: Insert Sample Loans
INSERT INTO loans VALUES
(9001,1,'Home Loan',5000000,8.25,'Active'),
(9002,2,'Personal Loan',800000,11.50,'Active'),
(9003,3,'Car Loan',1200000,9.10,'Active'),
(9004,4,'Personal Loan',500000,12.00,'Closed'),
(9005,5,'Business Loan',3000000,10.25,'Active');


-- =========================================================
-- Example Queries (MySQL syntax)
-- =========================================================

-- Example 1: Total Deposits
SELECT SUM(amount) AS total_deposits
FROM transactions
WHERE transaction_type = 'Deposit' AND transaction_status = 'Success';

-- Example 2: Customer Transaction Summary
SELECT c.customer_id, c.customer_name,
       COUNT(t.transaction_id) AS total_transactions,
       SUM(t.amount) AS total_transaction_value
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_id = t.account_id
WHERE t.transaction_status = 'Success'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_transaction_value DESC;

-- Example 3: Branch-wise Deposits
SELECT b.branch_name, SUM(t.amount) AS total_deposits
FROM branches b
JOIN accounts a ON b.branch_id = a.branch_id
JOIN transactions t ON a.account_id = t.account_id
WHERE t.transaction_type = 'Deposit' AND t.transaction_status = 'Success'
GROUP BY b.branch_name
ORDER BY total_deposits DESC;

-- Example 4: Identify High-Value Customers
SELECT c.customer_id, c.customer_name, SUM(a.current_balance) AS total_balance
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(a.current_balance) > 500000
ORDER BY total_balance DESC;

-- Example 5: Monthly Transaction Trend
-- MySQL has no DATE_TRUNC(); use DATE_FORMAT() instead
SELECT DATE_FORMAT(transaction_date, '%Y-%m-01') AS month,
       COUNT(*) AS transaction_count,
       SUM(amount) AS transaction_value
FROM transactions
WHERE transaction_status = 'Success'
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m-01')
ORDER BY month;

-- Example 6: Rank Customers by Balance
-- DENSE_RANK() requires MySQL 8.0+
SELECT c.customer_name,
       SUM(a.current_balance) AS total_balance,
       DENSE_RANK() OVER (ORDER BY SUM(a.current_balance) DESC) AS balance_rank
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.customer_name;

-- Example 7: Identify Potentially Unusual Transactions
SELECT account_id, transaction_id, transaction_date, amount
FROM transactions
WHERE amount > 100000 AND transaction_status = 'Success'
ORDER BY amount DESC;

-- =========================================================
-- Extra: A few more KPI queries worth practicing
-- =========================================================

-- Deposit-to-Withdrawal Ratio (overall)
SELECT
    SUM(CASE WHEN transaction_type = 'Deposit' THEN amount ELSE 0 END) AS total_deposits,
    SUM(CASE WHEN transaction_type = 'Withdrawal' THEN amount ELSE 0 END) AS total_withdrawals,
    ROUND(
        SUM(CASE WHEN transaction_type = 'Deposit' THEN amount ELSE 0 END) /
        NULLIF(SUM(CASE WHEN transaction_type = 'Withdrawal' THEN amount ELSE 0 END), 0), 2
    ) AS deposit_withdrawal_ratio
FROM transactions
WHERE transaction_status = 'Success';

-- Active vs Closed Loans, and total exposure by status
SELECT loan_status,
       COUNT(*) AS loan_count,
       SUM(loan_amount) AS total_loan_amount
FROM loans
GROUP BY loan_status;

-- Customer Loan Exposure (loans joined to customer)
SELECT c.customer_id, c.customer_name, l.loan_type, l.loan_amount, l.loan_status
FROM customers c
JOIN loans l ON c.customer_id = l.customer_id
ORDER BY l.loan_amount DESC;

-- Customer Segment Analysis: total balance and account count by segment
SELECT c.customer_segment,
       COUNT(DISTINCT c.customer_id) AS customer_count,
       COUNT(a.account_id) AS account_count,
       SUM(a.current_balance) AS total_balance
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.customer_segment
ORDER BY total_balance DESC;

-- Previous transaction amount per account using LAG()
SELECT account_id, transaction_id, transaction_date, amount,
       LAG(amount) OVER (PARTITION BY account_id ORDER BY transaction_date) AS previous_amount
FROM transactions
WHERE transaction_status = 'Success'
ORDER BY account_id, transaction_date;