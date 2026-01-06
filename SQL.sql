DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	age INT,
	country VARCHAR(50),
	income NUMERIC (12,2),
	created_at DATE DEFAULT CURRENT_DATE
);

CREATE TABLE loans (
    loan_id SERIAL PRIMARY KEY,
	customer_id INT REFERENCES customers(customer_id),
	loan_amount NUMERIC(12,2),
	interest_rate NUMERIC(5,2),
	loan_term_months INT,
	loan_status VARCHAR(20),
	start_date DATE
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
	loan_id INT REFERENCES loans(loan_id),
	payment_date DATE,
	AMOUNT numeric(12,2),
	is_late BOOLEAN
);

INSERT INTO customers (first_name, last_name, age, country, income) VALUES
('Juan', 'Perez', 35, 'Argentina', 85000),
('Maria', 'Gomez', 29, 'Argentina', 72000),
('Carlos', 'Lopez', 48, 'Chile', 120000),
('Ana', 'Silva', 41, 'Brazil', 98000),
('Pedro', 'Martinez', 55, 'Argentina', 65000);

INSERT INTO loans (customer_id, loan_amount, interest_rate, loan_term_months, loan_status, start_date) VALUES
(1, 20000, 18.5, 36, 'active', '2023-01-10'),
(2, 15000, 22.0, 24, 'paid', '2022-05-15'),
(3, 50000, 30.0, 48, 'default', '2021-09-01'),
(4, 30000, 16.0, 36, 'active', '2023-03-20'),
(5, 10000, 25.0, 12, 'paid', '2022-11-01');

INSERT INTO payments (loan_id, payment_date, amount, is_late) VALUES
(1, '2023-02-10', 700, false),
(1, '2023-03-10', 700, false),
(3, '2021-10-01', 1200, true),
(3, '2021-11-01', 1200, true),
(4, '2023-04-20', 900, false);

SELECT * FROM customers;
SELECT * FROM loans;
SELECT * FROM payments;


SELECT * FROM customers;
SELECT
    l.loan_id,
	c.first_name,
	c.last_name,
	l.loan_amount,
	l.interest_rate,
	l.loan_status
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id;


SELECT
    c.country,
	SUM(l.loan_amount) AS total_loan_amount
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
GROUP BY c.country
ORDER BY total_loan_amount DESC;


SELECT
    loan_status,
	COUNT(*) AS total_loans
FROM loans
GROUP BY loan_status;


SELECT
    loan_status,
	SUM(loan_amount) AS total_amount
FROM loans
GROUP BY loan_status;


SELECT
    COUNT(*) AS late_payments
FROM payments
WHERE is_late = true;


SELECT
    ROUND(
        100.0 * SUM(CASE WHEN is_late THEN 1 ELSE 0 END) / COUNT(*),
		2
	) AS late_payment_percentage
FROM payments;


SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(p.payment_id) AS late_payments
FROM payments p
JOIN loans l ON p.loan_id = l.loan_id
JOIN customers c ON l.customer_id = c.customer_id
WHERE p.is_late = true
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY late_payments DESC;


SELECT
    c.customer_id,
	c.first_name,
	c.last_name,
	c.income,
	l.loan_amount
FROM customers c
JOIN loans l ON c.customer_id = l.customer_id
WHERE l.loan_status = 'default'
    AND c.income > 50000;


SELECT
    l.loan_id,
	l.loan_amount,
	l.loan_status
FROM loans l
LEFT JOIN payments p ON l.loan_id = p.loan_id
WHERE p.payment_id IS NULL;


SELECT
    c.customer_id,
	c.first_name,
	c.last_name,
	COUNT(p.payment_id) AS total_payments,
	SUM(CASE WHEN p.is_late THEN 1 ELSE 0 END) AS late_payments,
	ROUND(
        100.0 * SUM(CASE WHEN p.is_late THEN 1 ELSE 0 END) /
		NULLIF(COUNT(p.payment_id), 0),
		2
	) AS late_payment_rate
FROM customers c
JOIN loans l ON c.customer_id = l.customer_id
JOIN payments p ON l.loan_id = p.loan_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY late_payment_rate DESC;


-- 1. Late paymets per customer (CTE)

WITH late_payments AS (
    SELECT
	    c.customer_id,
		c.first_name,
		c.last_name,
		COUNT(p.payment_id) AS late_payments
	FROM payments p
	JOIN loans l ON p.loan_id = l.loan_id
	JOIN customers c ON l.customer_id = c.customer_id
	WHERE p.is_late = true
	GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT *
FROM late_payments
ORDER BY late_payments DESC;


-- 2. Customer risk ranking (Window Function)

WITH late_payments AS (
    SELECT
	    c.customer_id,
		c.first_name,
		c.last_name,
		COUNT(p.payment_id) AS late_payments
	FROM payments p
	JOIN loans l ON p.loan_id = l.loan_id
	JOIN customers c ON l.customer_id = c.customer_id
	WHERE p.is_late = true
	GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
    *,
	RANK() OVER(ORDER BY late_payments DESC) AS risk_rank
FROM late_payments;


-- 3. Average late payments by country

WITH customer_late AS (
    SELECT
	    c.customer_id,
		c.country,
		COUNT(p.payment_id) AS late_payments
	FROM customers c
	JOIN loans l ON c.customer_id = l.customer_id
	JOIN payments p ON l.loan_id = p.loan_id
	WHERE p.is_late = true
	GROUP BY c.customer_id, c.country
)
SELECT
    country,
	AVG(late_payments) OVER (PARTITION BY country) AS avg_late_payments_country
FROM customer_late
ORDER BY avg_late_payments_country DESC;


-- 4. Cumulative payments per loan

SELECT
    loan_id,
	payment_date,
	amount,
	SUM(amount) OVER (
        PARTITION BY loan_id
		ORDER BY payment_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) AS cumulative_paid
FROM payments
ORDER BY loan_id, payment_date;


-- 5. Risk categorization

WITH risk_base AS (
    SELECT
	    c.customer_id,
		c.first_name,
		c.last_name,
		COUNT(p.payment_id) AS late_payments
	FROM customers c
	JOIN loans l ON c.customer_id = l.customer_id
	JOIN payments p ON l.loan_id = p.loan_id
	WHERE p.is_late = true
	GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
    *,
	CASE
	    WHEN late_payments >= 3 THEN 'HIGH RISK'
		WHEN late_payments = 2 THEN 'MEDIUM RISK'
		ELSE 'LOW RISK'
	END AS risk_category
FROM risk_base
ORDER BY late_payments DESC;


WITH late_stats AS (
    SELECT
	    c.customer_id,
		COUNT(p.payment_id) AS total_payments,
		SUM(CASE WHEN p.is_late THEN 1 ELSE 0 END) AS late_payments
	FROM customers c
	JOIN loans l ON c.customer_id = l.customer_id
	JOIN payments p ON l.loan_id = p.loan_id
	GROUP BY c.customer_id
)
SELECT
    customer_id,
	total_payments,
	late_payments,
	ROUND(late_payments::NUMERIC / total_payments, 2) AS late_ratio,
	CASE
	    WHEN late_payments::NUMERIC / total_payments > 0.3 THEN 'High Risk'
		WHEN late_payments::NUMERIC / total_payments > 0.1 THEN 'Medium Risk'
		ELSE 'Low Risk'
	END AS risk_segment
FROM late_stats
ORDER BY late_ratio DESC;


SELECT
    l.loan_id,
	l.loan_amount,
	l.interest_rate,
	COUNT(p.payment_id) FILTER (WHERE p.is_late) AS late_payments
FROM loans l
JOIN payments p ON l.loan_id = p.loan_id
GROUP BY l.loan_id, l.loan_amount, l.interest_rate
HAVING COUNT(p.payment_id) FILTER (WHERE p.is_late) >= 2
ORDER BY late_payments DESC;