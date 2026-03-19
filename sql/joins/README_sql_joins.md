# CBK Banking Sector — SQL Joins & UNION Analysis

Multi-table analysis of Kenya's banking sector using real 2024 CBK data.

---

## Skills Demonstrated

- INNER JOIN, LEFT JOIN, RIGHT JOIN, FULL JOIN
- JOIN across three tables
- UNION and UNION ALL
- Conditional aggregation with CASE WHEN inside COUNT
- CAST for data type handling

---

## Files

| File | Description |
|---|---|
| `cbk_banking_joins_and_union.sql` | Multi-table JOIN and UNION queries on CBK market share, profitability and NPL loan data |

---

## Key Findings

- Only National Bank of Kenya shows positive ROE (7.1%) despite an NPL ratio above 20% (33.2%) — warrants further investigation into provisioning strategy
- Bank name inconsistencies across tables (e.g. 'Limited' vs 'Ltd') highlight the need for unique ID keys in production database design
- `cbk_market_share` and `cbk_profitability` cover different bank populations (17 vs 39 banks), making direct asset average comparisons misleading

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
