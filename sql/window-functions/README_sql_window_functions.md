# CBK Banking Sector — SQL Window Functions Analysis

Advanced window function queries on Kenya's banking sector using real 2024 CBK data.

---

## Skills Demonstrated

- ROW_NUMBER, RANK, DENSE_RANK
- NTILE for quartile and percentile analysis
- Running totals using SUM as a window function
- LAG and LEAD for row-to-row comparisons
- FIRST_VALUE and LAST_VALUE with frame clauses
- PERCENT_RANK for relative ranking
- PARTITION BY for group-level calculations
- Subqueries to filter on window function results
- Combining JOINs with window functions

---

## Files

| File | Description |
|---|---|
| `cbk_banking_window_functions.sql` | Window function queries on CBK market share, profitability and NPL loan data — ranking, running totals, percentiles, health classification |

---

## Key Findings

- KCB alone holds 22.36% of Large peer group assets — top 3 banks control over 52%, indicating high concentration risk
- Citibank (40.1% ROE) and Standard Chartered (38.9% ROE) are the genuine top performers — Spire Bank's 102.1% ROE is a statistical distortion caused by negative shareholders funds
- 14 out of 39 banks reported negative ROE in 2024 — HFC Ltd (1.4%) marks the boundary between profitable and loss-making banks
- Access Bank Kenya (-159% ROE) and Ecobank (-90.9% ROE) are the worst performers in the sector
- Bank name inconsistencies across tables highlight the need for a unique bank_id in production database design

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

*Author: Lucy Wangui | BSc Statistics, Maseno University | 2026*
