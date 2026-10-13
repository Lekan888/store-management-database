# Store Management Database — Portfolio Copy

**Lekan Toriola | MySQL, SQL, Relational Database Design**

Repository: [Lekan888/store-management-database](https://github.com/Lekan888/store-management-database)

## Resume bullets

**Store Management Database | MySQL, SQL, GitHub Actions**

- Designed a five-table MySQL store database with two foreign-key relationships, 21 sample records and a three-table sales view.
- Developed six SQL reports using LEFT JOIN, GROUP BY, HAVING, CTEs and subqueries to summarize customer and product transactions, including zero-activity records.
- Verified data integrity through 31 baseline checks and behavioral tests for duplicate emails, invalid references, CHECK constraints, optional relationships and transaction rollback.
- Added GitHub Actions verification and documented reproducible setup, reporting assumptions and a tested fix for an employee default that violated its CHECK constraint.

## LinkedIn project description

Built a MySQL store database with five tables, two foreign-key relationships, 21 sample records and a three-table sales view. Added six reports using joins, GROUP BY, HAVING, CTEs and subqueries to examine customer totals, repeat buyers, product transactions and above-average values. Totals use recorded transaction amounts, and customer/product summaries include records with no transactions. The project includes 31 baseline verification checks, automated MySQL verification, constraint and rollback tests, reproducible setup instructions and an interview walkthrough. Also corrected an employee department default that violated its CHECK constraint.

**Skills:** SQL, MySQL, relational database design, reporting, data integrity, regression testing, GitHub Actions, technical documentation.

**Project link:** https://github.com/Lekan888/store-management-database

## GitHub repository description

MySQL store database: 5 tables, 21 sample records, a sales view and 6 SQL reports, with integrity checks, rollback tests, GitHub Actions and reproducible setup.

## Short portfolio case study

**Goal.** Demonstrate relational transaction modelling, SQL reporting and data-integrity verification through a store-data learning project.

**Implementation.** Built five InnoDB tables with two customer/product foreign keys and three CHECK constraints. The fixture contains 21 sample records and a three-table sales view. Six reports use joins, aggregation, HAVING, CTEs and subqueries to examine transaction detail, customer/product totals, repeat buyers and above-average values.

**Design decision.** Reports sum the stored transaction amount rather than the current catalogue price; the fixture demonstrates that these can differ. LEFT JOIN reports retain optional links and include customers/products with no transactions. Stable IDs distinguish matching names. An earlier merged fix replaced the invalid General department default with NULL for the optional field.

**Verification.** A GitHub Actions workflow imports the database into MySQL 8.0, checks all 31 verification results, executes the reports and tests constraints, the corrected default and rollback. The gate rejects FAIL results and malformed output; an intentionally changed amount tests failure detection. Eight Python unit tests exercise the gate.

**Current scope.** No application interface, inventory, quantity, currency, cost or multi-item order model is implemented. Recorded totals do not establish profit or unit sales. The audit row is historical seed data; no application routines or audit triggers are shipped. A temporary procedure exists only during behavioral tests and is dropped afterward.

**Possible future improvements.** Define transaction amount and required-field rules, introduce order items/inventory and historical pricing fields, and recover and test the original procedures/audit triggers if their definitions still exist.

## Evidence

| Claim | Implemented evidence |
| --- | --- |
| Schema, 21 sample rows, sales view and corrected department default | [Source](../store_management.sql) |
| Six runnable SQL reports | [Source](../reports.sql) |
| 31 baseline verification checks | [Source](../verify.sql) |
| Constraint, optional-link, default and rollback behavior | [Source](../tests/regression.sql) |
| Verification gate and eight unit tests | [Source](../scripts/check_verification.py) |
| Automated MySQL import, report execution and failure detection | [Source](../.github/workflows/mysql.yml) |
| Setup, prior validation record and reporting limits | [Source](../README.md) |
| Demonstration and interview notes | [Source](project-walkthrough.md) |

The sample counts describe the bundled fixture, not real operational scale. Future improvements above are suggestions, not completed features.
