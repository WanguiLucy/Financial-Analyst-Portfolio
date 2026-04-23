# Kenya Banking Sector Health Assessment — 2020 to 2024

A portfolio SQL project analyzing the health, structure, and risk profile of Kenya's banking sector using data extracted from the **Central Bank of Kenya (CBK) Bank Supervision Annual Reports (2020–2024)**.

**Author:** Lucy Wangui  
**Tools:** SQLite · DB Browser for SQLite  
**GitHub:** [WanguiLucy](https://github.com/WanguiLucy)

---

## Project Overview

This project uses four structured datasets derived from CBK supervisory data to answer 20 business-driven questions spanning market structure, profitability, credit risk, capital adequacy, and sector-wide stress. The analysis covers all CBK-licensed commercial banks across five reporting years.

---

## Datasets

| Table | Source | Description |
|---|---|---|
| `cbk_market_share` | CBK Bank Supervision Report | Total assets, deposits, deposit accounts, asset market share %, peer group classification |
| `cbk_profitability` | CBK Bank Supervision Report | Profit before tax, Return on Equity (ROE), Return on Assets (ROA) |
| `cbk_npl_loans` | CBK Bank Supervision Report | Gross loans, NPL ratio %, loan growth % |
| `cbk_capital_adequacy` | CBK Bank Supervision Report | Core capital to RWA %, total capital to RWA %, core capital to deposits %, core capital (KSh M) |

All monetary values are in **KSh Millions** unless otherwise stated.

---

## Business Questions Answered

### Market Structure
| # | Question |
|---|---|
| Q01 | Top 5 banks by total assets (2024) |
| Q06 | HHI market concentration index by year |
| Q17 | Concentration risk: top 5 banks' asset share over time |

### Profitability
| # | Question |
|---|---|
| Q03 | All loss-making bank–year combinations |
| Q07 | Profitability tier classification by year (ROE-based) |
| Q11 | Sector-wide ROE trend at peer group level |
| Q12 | YoY ROA change — top improvers and deteriorators |

### Credit Risk & Lending
| # | Question |
|---|---|
| Q02 | Average NPL ratio by peer group (2023) |
| Q04 | Year-by-year sector gross loan growth |
| Q09 | NPL ratio vs loan growth risk quadrant (2023) |
| Q13 | Rolling 3-year average NPL ratio per bank |
| Q15 | Loan-to-deposit ratio analysis by bank and year |
| Q16 | NPL coverage ratio estimation |

### Capital Adequacy & Compliance
| # | Question |
|---|---|
| Q05 | Banks below regulatory capital minimums |
| Q10 | Capital adequacy compliance scorecard (all years) |

### Growth & Structural Change
| # | Question |
|---|---|
| Q08 | Deposit account growth rate (CAGR) by peer group, 2020–2024 |
| Q14 | Bank asset rank shift: 2020 to 2024 |

### Composite & Advanced Metrics
| # | Question |
|---|---|
| Q18 | Composite bank health score — all four datasets (2023) |
| Q19 | Identifying and tracking systemically important banks (SIBs) |
| Q20 | Full sector stress index — 2020 to 2024 |

---

## SQL Techniques Used

- Window functions: `LAG()`, `RANK()`, `AVG() OVER()` with frame clauses (`ROWS BETWEEN`)
- Common Table Expressions (CTEs) and multi-CTE chaining
- Conditional aggregation with `CASE WHEN`
- `POWER()` for CAGR and HHI calculations
- Min-max normalisation for composite scoring
- SQLite median approximation using `LIMIT`/`OFFSET`
- Multi-table `JOIN` across all four datasets
- `NULLIF()` for safe division

---

## Regulatory Thresholds Applied

| Metric | CBK Minimum |
|---|---|
| Core Capital to RWA | ≥ 10.5% |
| Total Capital to RWA | ≥ 14.5% |
| Core Capital to Deposits | ≥ 8.0% |
| NPL Ratio (sector benchmark) | ≤ 15% |

---

## Key Findings

- **Market structure:** The sector maintained a competitive HHI of approximately 807 across the period, well below the 1,500 concentration threshold
- **NPL stress:** A significant proportion of banks breached the 15% NPL benchmark, particularly in 2020–2022
- **Capital compliance:** Most banks passed core capital requirements; compliance with the deposits ratio was the most variable
- **Deposit growth:** Large-tier banks recorded the strongest CAGR in deposit accounts between 2020 and 2024
- **SIBs:** A consistent group of 3 banks retained the qualification of systemically important based on market share and capital strength

---

## How to Run

1. Open **DB Browser for SQLite**
2. Import the four cleaned Excel/CSV files as tables using the names listed in the Datasets section above
3. Open `cbk_sector_health_assessment_2024.sql`
4. Run queries individually (Q01 through Q20) using the Execute SQL tab

> Each query is self-contained and labelled. Multi-CTE queries (Q08, Q18, Q19, Q20) should be run as a single block.

---

## Data Notes

- Bank names were standardised across source files to ensure consistent JOIN results; minor name inconsistencies in original CBK reports required manual reconciliation
- All data is sourced from publicly available CBK Bank Supervision Annual Reports
- This project is for portfolio and educational purposes only

---

## Repository Structure

```
project-banking/
│
├── cbk_sector_health_assessment_2024.sql   ← Main analysis script (20 queries)
├── README.md                ← This file
```
