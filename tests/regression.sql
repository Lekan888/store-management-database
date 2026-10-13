-- Behavioral checks in a disposable imported schema. Test changes are rolled back.
-- The temporary procedure is removed after success; it is not an application routine.
DROP PROCEDURE IF EXISTS test_portfolio_behavior;
DELIMITER $$
CREATE PROCEDURE test_portfolio_behavior()
BEGIN
    DECLARE rejected BOOLEAN DEFAULT FALSE;
    DECLARE new_transaction INT;
    DECLARE new_customer INT;
    DECLARE new_product INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF (SELECT SUM(amount) FROM transactions) <> 220.23
       OR (SELECT SUM(amount) FROM sales_view) <> 220.23
       OR (SELECT COUNT(*) FROM sales_view) <> 6
       OR (SELECT COUNT(DISTINCT transaction_id) FROM sales_view) <> 6
       OR (SELECT COUNT(t.transaction_id) FROM customers c
           LEFT JOIN transactions t ON t.customer_id = c.customer_id
           WHERE c.customer_id = 5) <> 0
       OR (SELECT SUM(amount) FROM transactions WHERE product_id = 1) <> 65.99
       OR (SELECT COUNT(*) FROM products WHERE price > (SELECT AVG(price) FROM products)) <> 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Store report baseline differs';
    END IF;

    START TRANSACTION;

    INSERT INTO customers (first_name, last_name, email)
    VALUES ('David', 'Johnson', 'report-check@example.test');
    SET new_customer = LAST_INSERT_ID();
    IF (SELECT COUNT(t.transaction_id) FROM customers c
        LEFT JOIN transactions t ON t.customer_id = c.customer_id
        WHERE c.customer_id = new_customer) <> 0
       OR (SELECT COUNT(*) FROM customers WHERE first_name = 'David' AND last_name = 'Johnson') <> 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Zero-transaction namesake not retained';
    END IF;

    INSERT INTO products (product_name, price) VALUES ('Unsold demo product', 1);
    SET new_product = LAST_INSERT_ID();
    IF (SELECT COUNT(t.transaction_id) FROM products p
        LEFT JOIN transactions t ON t.product_id = p.product_id
        WHERE p.product_id = new_product) <> 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unsold product counted as a transaction';
    END IF;

    INSERT INTO transactions (amount) VALUES (1);
    SET new_transaction = LAST_INSERT_ID();
    IF (SELECT COUNT(*) FROM transactions t
        LEFT JOIN customers c ON c.customer_id = t.customer_id
        LEFT JOIN products p ON p.product_id = t.product_id
        WHERE t.transaction_id = new_transaction
          AND t.customer_id IS NULL AND t.product_id IS NULL) <> 1
       OR (SELECT COUNT(*) FROM sales_view) <> 6 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Optional-link transaction behavior differs';
    END IF;

    INSERT INTO employees (employee_id, first_name, last_name, hire_date)
    VALUES (9999, 'Check', 'Only', '2026-01-01');
    IF NOT (SELECT department IS NULL FROM employees WHERE employee_id = 9999) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Omitted department no longer defaults to NULL';
    END IF;

    SET rejected = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR 1062 SET rejected = TRUE;
        UPDATE customers SET email = 'david@gmail.com' WHERE customer_id = 2;
    END;
    IF NOT rejected THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate customer email accepted';
    END IF;

    SET rejected = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR 1452 SET rejected = TRUE;
        UPDATE transactions SET customer_id = -1 WHERE transaction_id = 1;
    END;
    IF NOT rejected THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unknown customer reference accepted';
    END IF;

    SET rejected = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR 1452 SET rejected = TRUE;
        UPDATE transactions SET product_id = -1 WHERE transaction_id = 1;
    END;
    IF NOT rejected THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unknown product reference accepted';
    END IF;

    SET rejected = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR 3819 SET rejected = TRUE;
        UPDATE products SET price = 0 WHERE product_id = 1;
    END;
    IF NOT rejected THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Zero product price accepted';
    END IF;

    SET rejected = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR 3819 SET rejected = TRUE;
        UPDATE employees SET hourly_pay = 0 WHERE employee_id = 1001;
    END;
    IF NOT rejected THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Zero hourly pay accepted';
    END IF;

    SET rejected = FALSE;
    BEGIN
        DECLARE CONTINUE HANDLER FOR 3819 SET rejected = TRUE;
        UPDATE employees SET department = 'General' WHERE employee_id = 1001;
    END;
    IF NOT rejected THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid employee department accepted';
    END IF;

    UPDATE transactions SET amount = 26.99 WHERE transaction_id = 1;
    IF (SELECT amount FROM transactions WHERE transaction_id = 1) <> 26.99 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transaction update not applied';
    END IF;
    ROLLBACK;

    IF (SELECT COUNT(*) FROM customers) <> 5
       OR (SELECT COUNT(*) FROM products) <> 5
       OR (SELECT COUNT(*) FROM employees) <> 4
       OR (SELECT COUNT(*) FROM transactions) <> 6
       OR (SELECT amount FROM transactions WHERE transaction_id = 1) <> 25.99 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rollback did not restore store fixture';
    END IF;
    SELECT 'Store behavioral checks passed' AS result;
END$$
DELIMITER ;
CALL test_portfolio_behavior();
DROP PROCEDURE test_portfolio_behavior;
