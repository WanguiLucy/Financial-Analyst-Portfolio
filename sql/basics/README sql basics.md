# SQL Basics — CBK Banking Sector Analysis

Exploratory SQL queries on Kenya's banking sector using real data from the Central Bank of Kenya (CBK) Banking Supervision Report 2024.

---

## Skills Demonstrated

- Table creation and data types
- SELECT, WHERE, ORDER BY
- GROUP BY and aggregate functions (COUNT, SUM, AVG, MAX)
- HAVING clause for filtered aggregations
- Subqueries
- CASE WHEN for classification and conditional aggregation
- DISTINCT

---

## Files

| File | Description |
|---|---|
| `cbk_banking_basics.sql` | Exploratory queries on CBK market share data — peer group analysis, asset distribution, deposit accounts |
| `cbk_banking_aggregates_and_case_when.sql` | CASE WHEN classification, conditional aggregation, HAVING, subqueries |

---

## Data Sources

All datasets are publicly available from the Central Bank of Kenya.

| Dataset | Source |
|---|---|
| CBK Market Share Report 2024 | [Central Bank of Kenya](https://www.centralbank.go.ke/bank-supervision/) |
| CBK Banking Supervision Report 2024 | [Central Bank of Kenya](https://www.centralbank.go.ke/bank-supervision/) |

To run these scripts, download the datasets above and import them into PostgreSQL using the `CREATE TABLE` statements at the top of each `.sql` file.

---

## Tools Used

- PostgreSQL
- DBeaver

---

*Author: Lucy Wangui | BSc Statistics, Maseno University| 2026*
