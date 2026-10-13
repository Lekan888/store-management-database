# Presenting the store database

## Five-minute demonstration

1. Open the README's schema table. Explain transaction → customer and transaction → product; employees and the audit table are separate.
2. Import `store_management.sql` into a disposable MySQL 8.0 schema and run `verify.sql`. Expect 31 PASS results.
3. Run reports 1 and 2 in `reports.sql`. Explain why LEFT JOIN retains missing optional links and shows a customer with no transactions as zero.
4. Run reports 3 and 6. Explain HAVING for repeat buyers and the CTE average across all customers, including zero totals.
5. Run `tests/regression.sql`, then rerun `verify.sql`. Explain email/FK/CHECK rejection, the valid NULL department default and rollback.
6. Show the GitHub Actions result and how the gate rejects a deliberately changed recorded amount.

## Interview prompts

- **Is the recorded total revenue or profit?** It is the sum of recorded transaction amounts. No currency, cost, tax, discount or quantity model supports a profit claim.
- **Why use transaction amount instead of product price?** The current listed price can differ from a stored amount. Transaction 6 records 40.00 while its product lists 25.99.
- **How does the detail report differ from sales_view?** It retains nullable links with LEFT JOIN. The existing view uses INNER JOIN and omits those events.
- **What was the employee default defect?** General violated the allowed-department CHECK. The earlier merged fix uses NULL for an unspecified optional department; the test proves that insert works.
- **Is inventory or audit automation implemented?** No. Quantity/stock, multi-item orders and application triggers/routines remain future work.
