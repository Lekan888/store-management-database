# Store Management Database

A MySQL learning project with five InnoDB tables, two foreign-key relationships, 21 sample records, and a three-table `sales_view`. It models customer/product transactions and stores employee details separately.

## Files and run order

| File | Purpose | Order |
| --- | --- | --- |
| `store_management.sql` | Tables, constraints, sample records, and sales view | 1: import into a new database |
| `verify.sql` | 31 read-only checks with expected values and PASS/FAIL results | 2: run after a successful import |
| `README.md` | Setup, schema, report examples, constraint checks, and limitations | Read before importing |

The dump manages its internal table-loading order. Do not run its table sections individually.

## Reproducible setup

Use a running MySQL 8.0 server plus the `mysql` client or MySQL Workbench. The original export was made with **MySQL 8.0.46** and uses `utf8mb4_0900_ai_ci`; MySQL 5.7 and MariaDB are not supported targets for this dump.

The import account needs permission to create the target schema and its tables/view, insert data, and run the dump's DROP/ALTER/LOCK TABLES statements. Verification requires SELECT and visibility of the selected schema's metadata. The view uses `SQL SECURITY INVOKER`, so its caller needs SELECT access to the underlying tables; it has no hardcoded root definer.

From a terminal:

```sh
git clone https://github.com/Lekan888/store-management-database.git
cd store-management-database
mysql -u root -p
```

Substitute your configured local import account for `root`. At the `mysql>` prompt:

```sql
CREATE DATABASE store_management_demo
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE store_management_demo;
SOURCE store_management.sql;
SOURCE verify.sql;
```

Create a **new disposable schema**. If its name already exists, stop and choose another name before importing. The dump contains DROP TABLE statements, so rerunning it in an existing target replaces its five tables and sample data. There is no CREATE DATABASE or USE statement in the dump; the selected schema determines where the objects are created. Check the import output for errors before verification.

SOURCE is a `mysql` client command and works when the client is launched from Windows PowerShell. In Workbench, run CREATE DATABASE and USE first, then open and execute `store_management.sql` followed by `verify.sql` in the same selected schema. Do not paste SOURCE commands into Workbench's SQL editor.

## Schema and existing features

| Table | Role | Sample rows |
| --- | --- | ---: |
| `customers` | Customer names and optional unique email | 5 |
| `products` | Product names and optional positive price | 5 |
| `employees` | Employee details, pay, hire date, job, and department | 4 |
| `transactions` | Recorded amount and optional customer/product references | 6 |
| `audit_log` | A previously recorded transaction event | 1 |
| **Total** | Base-table records; the view adds no stored records | **21** |

`transactions.customer_id` references `customers.customer_id`, and `transactions.product_id` references `products.product_id`. The employees table is standalone: transactions do not record which employee handled a sale. The audit table stores a transaction ID but has no foreign-key constraint.

The schema includes primary keys, AUTO_INCREMENT on four tables, customer email uniqueness, selected NOT NULL columns, and three CHECK constraints: product price >0, hourly pay >0, and employee department in HR/Management/Sales/IT. Employee IDs must be supplied explicitly. Email, price, hourly pay, department, and transaction reference columns allow NULL.

The original employee department default was `General`, which its CHECK constraint rejected. The default is now NULL, matching the existing nullable column without inventing a department assignment. The allowed non-null department values are unchanged.

`sales_view` joins transactions to customers and products and exposes transaction ID, customer names, product name, and the recorded transaction amount. Its INNER JOINs omit transactions with missing optional customer/product references. All six sample transactions have valid references, so the view contains six rows.

## Verification and expected results

`verify.sql` reports the selected database and server version, then returns **31 checks** with `check_name`, `expected_value`, `actual_value`, and `result`. Every check should be PASS on a clean import. The file is read-only and does not raise an error for FAIL; automated runners must inspect the result column.

The checks cover object/engine counts, all row counts above, both foreign keys and their orphan records, unique customer email, the three CHECK definitions and supplied values, the corrected department default, view security/results, and missing procedure/function/trigger definitions. It also checks audit-reference consistency in this fixture; that relationship is not enforced by a foreign key.

| Check or report | Expected snapshot result |
| --- | --- |
| Base tables / views | 5 / 1 |
| Foreign keys / CHECK constraints | 2 / 3 |
| View rows | 6 |
| Sum of recorded transaction amounts | 220.23 |
| Customer 2's recorded total | 85.50 |
| Duplicate non-null customer emails or view transaction IDs | 0 |
| Orphan customer/product references | 0 |
| NULL transaction references in this fixture | 0; the schema permits them |
| Procedure/function definitions / triggers | 0 / 0 |

## Reporting examples

### Customer totals, including customers with no transactions

```sql
SELECT c.customer_id, c.first_name, c.last_name,
       COUNT(t.transaction_id) AS transaction_count,
       COALESCE(SUM(t.amount), 0) AS recorded_total
FROM customers AS c
LEFT JOIN transactions AS t ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY recorded_total DESC, c.customer_id;
```

| customer_id | first_name | last_name | transaction_count | recorded_total |
| --- | --- | --- | ---: | ---: |
| 2 | Sarah | Williams | 2 | 85.50 |
| 1 | David | Johnson | 2 | 60.99 |
| 3 | Michael | Brown | 1 | 60.75 |
| 4 | Emaily | Davis | 1 | 12.99 |
| 5 | Daniel | Wilson | 0 | 0.00 |

To show only repeat buyers, add `HAVING COUNT(t.transaction_id) > 1` after GROUP BY and before ORDER BY. The sample result contains customers 2 and 1, in that order.

### Products above the average listed price

```sql
SELECT product_id, product_name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY product_id;
```

Expected: Keyboard (product 2, 45.50) and Headphones (product 5, 60.75).

Reports use the recorded `transactions.amount`, not the current product price. Transaction 6 records 40.00 for a Wireless Mouse whose current listed price is 25.99; the sample does not explain that difference. The schema stores no quantity, historical unit price, tax, discount, or currency code. Do not infer profit, unit sales, or a specific currency from these totals.

## Manual constraint and rollback checks

Use the disposable schema. Run START TRANSACTION before each UPDATE and ROLLBACK afterward, executing statements individually and completing ROLLBACK after an expected error.

| UPDATE attempt | Expected MySQL 8.0 behavior |
| --- | --- |
| `UPDATE customers SET email = 'david@gmail.com' WHERE customer_id = 2;` | Duplicate-key error 1062 |
| `UPDATE transactions SET customer_id = 999999 WHERE transaction_id = 1;` | Foreign-key error 1452 |
| `UPDATE transactions SET product_id = 999999 WHERE transaction_id = 1;` | Foreign-key error 1452 |
| `UPDATE products SET price = 0 WHERE product_id = 1;` | CHECK error 3819 |
| `UPDATE employees SET hourly_pay = 0 WHERE employee_id = 1001;` | CHECK error 3819 |
| `UPDATE employees SET department = 'General' WHERE employee_id = 1001;` | CHECK error 3819 |

The corrected default can be checked without retaining a test record:

```sql
START TRANSACTION;
INSERT INTO employees (employee_id, first_name, last_name, hire_date)
VALUES (9999, 'Check', 'Only', '2026-01-01');
SELECT department IS NULL AS unspecified_department
FROM employees WHERE employee_id = 9999; -- 1
ROLLBACK;
```

An InnoDB transaction demonstration:

```sql
START TRANSACTION;
UPDATE transactions SET amount = 26.99 WHERE transaction_id = 1;
SELECT amount FROM transactions WHERE transaction_id = 1; -- 26.99
ROLLBACK;
SELECT amount FROM transactions WHERE transaction_id = 1; -- 25.99 again
```

Keep expected-error checks separate from the normal verification batch. Run `verify.sql` afterward to confirm the sample remains intact. These examples demonstrate transaction behavior, not a stock-control or payment-processing workflow.

## Portfolio description

Designed a five-table MySQL store database with customer/product transaction relationships, 21 sample records, and a three-table sales view. Verified reproducible setup on MySQL 8.0.46 using a non-root account and 31 checks. Added tested SQL reporting examples using LEFT JOIN, aggregation, GROUP BY/HAVING, and a subquery; corrected an employee default that violated its CHECK constraint and removed the view's hardcoded root dependency.

## Limitations and future improvements

This export contains **no stored procedure/function or trigger definitions**. Its audit row is historical data; new transactions are not automatically logged. Salary is stored directly and is not recalculated from hourly pay. Earlier README claims about procedures and triggers cannot be recreated from the committed dump. Recover actual definitions from the original working database before claiming those features; `mysqldump --routines --triggers` exports them only if they exist and the account has the required privileges.

Transaction references are nullable, amounts have no positive-value CHECK constraint, and price/amount use DECIMAL(5,2). There is no inventory, quantity, reorder level, employee-to-sale relationship, or multi-item order model.

Future work could recover and test actual procedures/audit triggers, define required transaction fields and amount rules, add an order-items/inventory model, and introduce currency and historical pricing fields. These are not existing features of this project.

## Validation record

Validated on **12 October 2026** using MySQL **8.0.46-0ubuntu0.24.04.3** on Linux:

- Reproduced the original default defect: inserting an employee without a department failed with CHECK error 3819.
- Fresh import through the documented SOURCE flow using a non-root account with schema-scoped privileges: passed.
- All 31 verification checks: PASS.
- Sales view creation and query access with the importing account as definer and SQL SECURITY INVOKER: passed.
- Unique email rejected a duplicate with error 1062; both customer and product foreign keys rejected invalid references with error 1452.
- Zero price, zero hourly pay, and department General were rejected with CHECK error 3819.
- An employee with an omitted department was accepted with NULL, then rolled back.
- Transaction rollback restored amount 25.99 after a temporary change to 26.99.
- Verification detected a deliberately changed amount; rollback restored all 31 PASS results.
- Customer totals, the HAVING repeat-buyer variant, and the above-average-price subquery matched the documented results.
- Reimport restored the snapshot and all 31 PASS results.

Other server versions and operating systems have not been tested. Windows client/Workbench instructions are documented, but the validation above was performed on Linux.

## Author

Toriola Lekan
