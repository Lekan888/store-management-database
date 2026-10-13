-- Six read-only reports. Import store_management.sql first.
-- Totals use recorded transactions.amount, not the current product price.
-- Amounts have no specified currency; transaction counts are not unit quantities.

-- 1. Transaction detail. LEFT JOIN retains optional missing relationships.
SELECT t.transaction_id, t.customer_id,
       CONCAT(c.first_name, ' ', c.last_name) AS customer,
       t.product_id, p.product_name, t.amount AS recorded_amount
FROM transactions AS t
LEFT JOIN customers AS c ON c.customer_id = t.customer_id
LEFT JOIN products AS p ON p.product_id = t.product_id
ORDER BY t.transaction_id;

-- 2. Customer totals, including customers with no transactions.
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer,
       COUNT(t.transaction_id) AS transaction_count,
       COALESCE(SUM(t.amount), 0) AS recorded_total
FROM customers AS c
LEFT JOIN transactions AS t ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY recorded_total DESC, c.customer_id;

-- 3. Repeat buyers. HAVING filters the completed groups.
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer,
       COUNT(t.transaction_id) AS transaction_count,
       SUM(t.amount) AS recorded_total
FROM customers AS c
JOIN transactions AS t ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(t.transaction_id) > 1
ORDER BY recorded_total DESC, c.customer_id;

-- 4. Product transaction totals, including products with no transactions.
SELECT p.product_id, p.product_name,
       COUNT(t.transaction_id) AS transaction_count,
       COALESCE(SUM(t.amount), 0) AS recorded_total
FROM products AS p
LEFT JOIN transactions AS t ON t.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY recorded_total DESC, p.product_id;

-- 5. Products above the average current listed price.
SELECT product_id, product_name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY product_id;

-- 6. Customers above the average recorded total across ALL customers.
WITH customer_totals AS (
    SELECT c.customer_id, c.first_name, c.last_name,
           COALESCE(SUM(t.amount), 0) AS recorded_total
    FROM customers AS c
    LEFT JOIN transactions AS t ON t.customer_id = c.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT customer_id, CONCAT(first_name, ' ', last_name) AS customer, recorded_total
FROM customer_totals
WHERE recorded_total > (SELECT AVG(recorded_total) FROM customer_totals)
ORDER BY recorded_total DESC, customer_id;
