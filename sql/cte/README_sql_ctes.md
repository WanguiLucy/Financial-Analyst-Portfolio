# CBK Banking Sector — SQL CTE Analysis

## Overview
This project contains a structured series of SQL queries using Common Table Expressions (CTEs) applied to Central Bank of Kenya (CBK) banking sector data. The queries progress from beginner to advanced level, demonstrating a thorough understanding of SQL for financial data analysis.

## Dataset
The analysis is built on the following CBK tables:
- `cbk_market_share` — bank asset sizes, deposit figures, peer groups, and market rankings
- `cbk_profitability` — ROE, profit before tax, and related profitability metrics
- `cbk_npl_loans` — NPL ratios for 2023 and 2024
- `cbk_capital_adequacy` — capital adequacy and RWA ratios

## Structure

### Beginner — Single CTEs
- Deposit share analysis — filtering banks above 5% sector share
- NPL ratio comparison — identifying banks above the 2024 sector average
- Asset ranking — returning the top 10 banks by total assets

### Intermediate — Chained & Multiple CTEs
- Peer group ROE benchmarking — flagging banks as Above or Below Average relative to their peer group
- Dual-risk identification — joining loss-making and capital-thin banks to find overlap
- NPL deterioration ranking — isolating and ranking banks whose NPL worsened from 2023 to 2024

### Advanced — CTEs Replacing Subqueries
- HHI market concentration index — rewritten from inline subquery to CTE
- Top 5 deposit control — returning bank names alongside cumulative deposit percentage
- Full tiering framework — classifying all banks into Tier 1 through Tier 4 using profitability, NPL, and capital metrics across three CTEs

### Challenge
- Recursive CTE — cumulative market share ladder stopping at the bank that pushes total past 80%

## Skills Demonstrated
- Window functions (`RANK`, `ROW_NUMBER`, `AVG OVER`, `SUM OVER`)
- Multi-CTE chaining and referencing
- Conditional classification using `CASE WHEN`
- Recursive CTEs
- Cross joins and aggregate logic
- Financial metrics: ROE, NPL ratio, HHI, capital adequacy

## Author
Personal portfolio project — part of a structured data analytics learning path.
