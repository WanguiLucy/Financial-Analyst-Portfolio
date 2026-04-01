# Kenya Banking Sector Health Assessment 2024
**Author:** Lucy Wangui | BSc Statistics, Maseno University  
**Data:** Central Bank of Kenya Banking Supervision Report 2024  
**Tools:** PostgreSQL, DBeaver  

---

## Project Overview

A full SQL-based health assessment of Kenya's banking sector covering 39 banks across 6 analytical dimensions: market concentration, profitability, credit quality, bank tiering, capital adequacy, and loan dynamics. Data is sourced directly from the CBK Banking Supervision Report 2024.

---

## Datasets

| Table | Description | Rows |
|---|---|---|
| `cbk_market_share` | Assets, deposits, peer group, market rank | 17 banks |
| `cbk_profitability` | ROE, ROA, profit before tax, shareholders funds | 39 banks |
| `cbk_npl_loans` | Gross loans, NPL ratios for Dec 2023 and Dec 2024 | 38 banks |
| `cbk_capital_adequacy` | Core capital, total capital, RWA, CBK ratio thresholds | 29 banks |

---

## Key Findings

**Market Concentration**
- HHI of 807 classifies the sector as Competitive, but top 5 banks control 59.28% of sector assets and deposits — a gap that warrants dual-metric monitoring by CBK
- Only 10 out of 17 banks are needed to account for 80% of sector assets

**Profitability**
- 10 out of 39 banks (25%) are loss-making in 2024, but their combined losses represent only -4% of total sector profit — large banks absorb the impact
- Medium banks show negative average ROE (-0.86%), heavily skewed by Ecobank (-90.9%) and Access Bank (-159%)
- Bank size does not predict profitability — Citibank outperforms much larger peers on ROE

**Credit Quality (NPL)**
- 37 out of 38 banks exceed CBK's 5% NPL benchmark
- Sector weighted average NPL rose from 15.52% (2023) to 17.11% (2024) — a 1.59 point deterioration in one year
- 22 banks worsened, 15 improved; Guaranty Trust Bank deteriorated fastest (+23 points)
- 14 banks show NPL Growth Only — shrinking loan books with rising bad loans, the most structurally concerning signal

**Bank Tiering (Multi-metric Classification)**
- Tier 2 Stable: 5 banks — Citibank, Prime, Family, Bank of India, Co-operative Bank
- Tier 3 Watch: 1 bank — National Bank of Kenya
- Tier 4 Distressed: 2 banks — Ecobank, SBM Bank
- 9 banks returned no data due to name formatting inconsistencies across tables (see Data Limitations)

**Capital Adequacy**
- KCB holds the strongest core capital base at KSh 144,770M
- Family Bank (-78.7%) and Gulf African Bank (-1.4%) flagged for negative core-capital-to-deposits ratio — a serious depositor protection risk
- Bank of India holds the largest capital buffer above CBK minimum (+70.8 points)

**Loan Dynamics**
- 12 banks flagged as Double Risk: growing loan books AND growing NPLs simultaneously
- DIB Bank Kenya most extreme — NPL surged 150% on just 5% loan growth
- UBA Kenya best performer — loans -56%, NPLs -86% (active portfolio cleanup)

---

## Data Limitations

- **Name inconsistencies across tables** — 5 banks have formatting mismatches between `cbk_market_share` and other tables (e.g. `KCB Bank Kenya Limited` vs `KCB Bank Kenya Ltd`). This causes NULL results in cross-table joins, particularly in Section 4 tiering. Identified and documented in Section 7.
- **Coverage gaps** — `cbk_capital_adequacy` covers 29 banks; not all 39 banks in profitability have capital data
- All findings are directionally correct; exact figures on joined queries may shift with standardised bank names

---

## SQL Structure

| Section | Focus |
|---|---|
| Section 1 | Market share and concentration analysis |
| Section 2 | Profitability ranking and peer group comparison |
| Section 3 | NPL benchmarking, deterioration ranking, weighted averages |
| Section 4 | Multi-metric bank tiering framework |
| Section 5 | Capital adequacy and CBK regulatory threshold analysis |
| Section 6 | Loan book dynamics and double risk flagging |
| Section 7 | Data quality — name mismatch diagnosis |
