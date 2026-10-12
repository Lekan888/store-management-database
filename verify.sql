-- Run after store_management.sql in a fresh, selected schema.
-- Read-only: check result values; FAIL does not raise a SQL error.
-- Metadata checks require visibility of this schema's imported objects.

SELECT DATABASE() AS selected_database, VERSION() AS server_version;

SELECT check_name, expected_value, actual_value,
       CASE WHEN actual_value = expected_value THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
    SELECT 'base_table_count' AS check_name, '5' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE') AS CHAR) AS actual_value
    UNION ALL
    SELECT 'innodb_table_count' AS check_name, '5' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE' AND ENGINE = 'InnoDB') AS CHAR) AS actual_value
    UNION ALL
    SELECT 'view_count' AS check_name, '1' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE()) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'sales_view_definition' AS check_name, '1' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sales_view') AS CHAR) AS actual_value
    UNION ALL
    SELECT 'audit_log_rows' AS check_name, '1' AS expected_value,
           CAST((SELECT COUNT(*) FROM audit_log) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'customers_rows' AS check_name, '5' AS expected_value,
           CAST((SELECT COUNT(*) FROM customers) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'employees_rows' AS check_name, '4' AS expected_value,
           CAST((SELECT COUNT(*) FROM employees) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'products_rows' AS check_name, '5' AS expected_value,
           CAST((SELECT COUNT(*) FROM products) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'transactions_rows' AS check_name, '6' AS expected_value,
           CAST((SELECT COUNT(*) FROM transactions) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'foreign_key_count' AS check_name, '2' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() AND CONSTRAINT_TYPE = 'FOREIGN KEY') AS CHAR) AS actual_value
    UNION ALL
    SELECT 'check_constraint_count' AS check_name, '3' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() AND CONSTRAINT_TYPE = 'CHECK') AS CHAR) AS actual_value
    UNION ALL
    SELECT 'customer_email_unique_definition' AS check_name, '1' AS expected_value,
           CAST((SELECT COUNT(*) FROM (
      SELECT INDEX_NAME FROM information_schema.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'customers' AND NON_UNIQUE = 0
      GROUP BY INDEX_NAME
      HAVING GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX SEPARATOR ',') = 'email'
    ) AS email_indexes) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'duplicate_customer_emails' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM (
      SELECT email FROM customers WHERE email IS NOT NULL
      GROUP BY email HAVING COUNT(*) > 1
    ) AS duplicate_emails) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'orphan_transactions_customer' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM transactions t LEFT JOIN customers c ON t.customer_id = c.customer_id WHERE t.customer_id IS NOT NULL AND c.customer_id IS NULL) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'orphan_transactions_product' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM transactions t LEFT JOIN products p ON t.product_id = p.product_id WHERE t.product_id IS NOT NULL AND p.product_id IS NULL) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'fixture_null_transaction_links' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM transactions WHERE customer_id IS NULL OR product_id IS NULL) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'fixture_invalid_prices' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM products WHERE price IS NOT NULL AND price <= 0) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'fixture_invalid_hourly_pay' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM employees WHERE hourly_pay IS NOT NULL AND hourly_pay <= 0) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'fixture_invalid_departments' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM employees WHERE department IS NOT NULL AND department NOT IN ('HR', 'Management', 'Sales', 'IT')) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'employee_department_default_null' AS check_name, '1' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'employees' AND COLUMN_NAME = 'department' AND COLUMN_DEFAULT IS NULL) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'sales_view_rows' AS check_name, '6' AS expected_value,
           CAST((SELECT COUNT(*) FROM sales_view) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'sales_view_recorded_total' AS check_name, '220.23' AS expected_value,
           CAST((SELECT SUM(amount) FROM sales_view) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'sales_view_first_transaction' AS check_name, '1:David:Johnson:Wireless Mouse:25.99' AS expected_value,
           CAST((SELECT CONCAT_WS(':', transaction_id, first_name, last_name, product_name, amount) FROM sales_view WHERE transaction_id = 1) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'duplicate_sales_view_transactions' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM (
      SELECT transaction_id FROM sales_view GROUP BY transaction_id HAVING COUNT(*) > 1
    ) AS duplicate_view_rows) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'customer_2_recorded_total' AS check_name, '85.50' AS expected_value,
           CAST((SELECT SUM(amount) FROM transactions WHERE customer_id = 2) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'transactions_recorded_total' AS check_name, '220.23' AS expected_value,
           CAST((SELECT SUM(amount) FROM transactions) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'shipped_routine_count' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE()) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'shipped_trigger_count' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = DATABASE()) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'foreign_key_checks_enabled' AS check_name, '1' AS expected_value,
           CAST((SELECT @@SESSION.foreign_key_checks) AS CHAR) AS actual_value
    UNION ALL
    SELECT 'sales_view_invoker_security' AS check_name, '1' AS expected_value,
           CAST((SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sales_view' AND SECURITY_TYPE = 'INVOKER') AS CHAR) AS actual_value
    UNION ALL
    SELECT 'fixture_orphan_audit_transaction' AS check_name, '0' AS expected_value,
           CAST((SELECT COUNT(*) FROM audit_log a LEFT JOIN transactions t ON a.transaction_id = t.transaction_id WHERE a.transaction_id IS NOT NULL AND t.transaction_id IS NULL) AS CHAR) AS actual_value
) AS checks
ORDER BY check_name;
