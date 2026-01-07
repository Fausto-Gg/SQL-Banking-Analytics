SQL Banking Analytics

--Project Overview:

This project simulates a banking analytics environment using PostgreSQL to analyze customers, loans, and payments data.
The goal is to demonstrate real-world SQL skills commonly required in banking, fintech, and financial analytics roles.


The project focuses on:

  -Relational data modeling

  -Business-oriented SQL queries

  -Advanced SQL techniques (CTEs, window functions)

  -Analytical thinking applied to financial data


--Database Schema

The database consists of three core tables:

  -Customers

    customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR,
    last_name VARCHAR,
    age INT,
    country VARCHAR,
    income NUMERIC,
    created_at DATE
)


  -Loans

    loans (
    loan_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    loan_amount NUMERIC,
    interest_rate NUMERIC,
    loan_term_months INT,
    loan_status VARCHAR,
    start_date DATE
)


  -Payments

    payments (
    payment_id SERIAL PRIMARY KEY,
    loan_id INT REFERENCES loans(loan_id),
    payment_date DATE,
    amount NUMERIC,
    is_late BOOLEAN
)


--Business Questions Answered

This project answers common banking analytics questions, such as:

  -Which customers have the most late payments?

  -What is the total amount paid per loan over time?

  -How do payments accumulate month by month?

  -Which loans present higher risk indicators?

  -How does customer income relate to loan behavior?


--SQL Skills Demonstrated

This project showcases strong SQL fundamentals and advanced techniques:

  -Core SQL

    -SELECT, WHERE, GROUP BY, ORDER BY

    -JOIN (INNER JOIN, multi-table joins)

    -Aggregate functions (SUM, COUNT, AVG)

  --Advanced SQL

    -Common Table Expressions (CTEs)

    -Window Functions

      -SUM() OVER (PARTITION BY … ORDER BY …)

      -Running totals

    -Business-focused aggregations

    -Clean and readable query structure


--Example Analysis:

-Customers with Late Payments

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


-Cumulative Payments per Loan (Window Function)

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


--Tools & Technologies

  -PostgreSQL

  -pgAdmin

  -SQL (CTEs, Window Functions)

  -Git & GitHub


--How to Run the Project

1 - Create a PostgreSQL database

2 - Run the SQL script: "SQL.sql"

3 - Explore the queries directly in pgAdmin or any PostgreSQL client


--Why This Project Matters

This project is designed to mirror real tasks performed by:

  -Data Analysts

  -Business Analysts

  -Risk Analysts

  -Banking / Fintech Analysts

It demonstrates:

  -Practical SQL proficiency

  -Analytical thinking

  -Clean, readable, and maintainable queries

  -Understanding of financial data structures


--Author

Fausto Gallo
Data Analyst / Data Engineer
GitHub: https://github.com/Fausto-Gg