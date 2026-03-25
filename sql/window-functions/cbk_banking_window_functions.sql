-- ============================================
-- CBK Banking Sector — Window Functions Analysis
-- Author: Lucy Wangui
-- Data: Central Bank of Kenya 2024
-- Tools: PostgreSQL, DBeaver
-- ============================================

--1. Assign a row number to each bank ordered by total_assets_ksh_m descending. Return bank_name, total_assets_ksh_m and row_num.
select
	bank_name,
	total_assets_ksh_m,
	row_number() over(order by total_assets_ksh_m desc) as row_num
from
	cbk_market_share cms ; 

--2. Rank banks by asset_market_share_pct descending using both RANK() and DENSE_RANK(). Return bank_name, asset_market_share_pct, rank and dense_rank. Where do the two differ?
select
	bank_name,
	asset_market_share_pct,
	rank() over(order by asset_market_share_pct desc) as rank,
	dense_rank() over(order by asset_market_share_pct desc) as dense_rank
from
	cbk_market_share cms ;

-- RANK() vs DENSE_RANK() produce identical results here because
-- no two banks share the same asset_market_share_pct in this dataset
-- If two banks had equal shares e.g. both at 5.5%:
-- RANK()       would give them both rank 5, next bank gets rank 7 (skips 6)
-- DENSE_RANK() would give them both rank 5, next bank gets rank 6 (no gap)

--3. Using cbk_profitability, rank banks by profit_before_tax_ksh_m within each peer_group. Return bank_name, peer_group, profit_before_tax_ksh_m and profit_rank.
select
	cp.bank_name,
	cms.peer_group,
	cp.profit_before_tax_ksh_m,
	rank() over ( partition by cms.peer_group
order by
	profit_before_tax_ksh_m desc) as profit_rank
from
	cbk_profitability cp
join cbk_market_share cms on
	cp.bank_name = cms.bank_name;

-- JOIN on bank_name reduces results from 17 to 12 due to name inconsistencies
-- across tables e.g. 'KCB Bank Kenya Limited' vs 'KCB Bank Kenya Ltd'
-- A unique bank_id would resolve this in production


--4. Show a running total of total_deposits_ksh_m ordered by market_rank. Return bank_name, market_rank, total_deposits_ksh_m and running_total_deposits.

select
	bank_name,
	market_rank,
	total_deposits_ksh_m,
	sum(total_deposits_ksh_m) over (
order by
	market_rank ) as running_total
from
	cbk_market_share cms ;


--5. Divide all banks into 4 quartiles based on shareholders_funds_ksh_m. Return bank_name, shareholders_funds_ksh_m and quartile. Label what each quartile represents in a comment.
select
	bank_name,
	shareholders_funds_ksh_m,
	ntile(4) over (
	order by shareholders_funds_ksh_m) as quartile
from
	cbk_profitability cp ;

-- Quartile 1: Bottom 25% — lowest shareholders funds (weakest capital base)
-- Quartile 2: Lower middle 25%
-- Quartile 3: Upper middle 25%
-- Quartile 4: Top 25% — highest shareholders funds (strongest capital base)
-- Quartile 4 starts at KSh 65,417M (Stanbic) and goes up to KSh 183,715M (KCB)
-- That's a KSh 118,298M gap within the same quartile
-- This confirms NTILE splits by row count not value range
-- A large value spread within one quartile shows high inequality in capital distribution


--6. Show each bank's NPL ratio for Dec 2024, the previous bank's NPL ratio (ordered by npl_ratio_dec24_pct), 
--and the difference between them. Return bank_name, npl_ratio_dec24_pct, prev_npl_ratio and difference.

 select
	bank_name,
	npl_ratio_dec24_pct,
	lag(npl_ratio_dec24_pct, 1) over (
order by
	cnl.npl_ratio_dec24_pct ) as prev_npl_ratio,
	npl_ratio_dec24_pct-lag(npl_ratio_dec24_pct, 1) over (
order by
	cnl.npl_ratio_dec24_pct ) as difference
from
	cbk_npl_loans cnl;

 -- First row returns NULL for prev_npl_ratio as there is no preceding row
-- difference column shows the gap in NPL ratio between consecutive banks
-- when ordered by NPL ratio, a large difference flags a significant jump in loan quality

 --7. Using cbk_profitability ordered by return_on_equity_pct descending, show each bank's ROE and the next bank's ROE. Return bank_name, 
--return_on_equity_pct and next_bank_roe and show how far apart consecutive banks are.
 select
	bank_name,
	return_on_equity_pct,
	lead(return_on_equity_pct, 1) over(order by return_on_equity_pct desc) as next_bank_roe,
	return_on_equity_pct-lead(return_on_equity_pct, 1) over(order by return_on_equity_pct desc) as roe_gap
from
	cbk_profitability cp ;

 -- Ordered DESC so each row shows the drop in ROE to the next bank
-- Large gaps between consecutive ROE values highlight performance outliers compared to the next bank

 
 --8. Using cbk_market_share, for each peer_group:
	--Rank banks by total_assets_ksh_m descending
	--Show the running total of assets within each peer group
	--Show what percentage of the peer group's total assets each bank represents
	--Return bank_name, peer_group, total_assets_ksh_m, asset_rank, running_total and pct_of_group.
 
 select
	bank_name,
	peer_group,
	total_assets_ksh_m,
	rank() over (partition by peer_group
order by 
	total_assets_ksh_m desc) as asset_rank,
	sum(total_assets_ksh_m) over(partition by peer_group order by total_assets_ksh_m desc) as running_total,
	round(total_assets_ksh_m  *100 / sum(total_assets_ksh_m) over (partition by peer_group ),2) || '%'
 as pct_of_group
from
	cbk_market_share cms ;
 
 
 -- Large peer group shows high asset concentration:
-- KCB alone holds 22.36% of Large bank assets
-- Top 3 banks (KCB, Equity, Co-op) control over 52% of Large group assets
-- Medium peer group is more evenly distributed (17.1% to 7.72%)
-- This concentration risk is a key finding for CBK regulatory oversight
 
 
 --9. Using cbk_market_share, for each peer_group show each bank alongside:
	--The name of the largest bank in their peer group
	--The name of the smallest bank in their peer group
	--Return bank_name, peer_group, total_assets_ksh_m, largest_in_group and smallest_in_group.
 
 select
	bank_name,
	peer_group,
	total_assets_ksh_m,
	first_value(bank_name) over(partition by peer_group order by total_assets_ksh_m desc ) as largest_in_group,
	last_value(bank_name) over (partition by peer_group
order by
	total_assets_ksh_m desc rows between unbounded preceding and unbounded following ) as smallest_in_group
from
	cbk_market_share cms ;
 
 -- LAST_VALUE requires ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
-- Without this frame clause, LAST_VALUE returns the current row not the partition's last row
-- Default frame is ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
 
 
 --10. Using cbk_profitability, calculate the percent rank of each bank by profit_before_tax_ksh_m.
	--Return bank_name, profit_before_tax_ksh_m and profit_percent_rank.
	--Which banks are in the top 25%?
 
 --10.A
 select
		bank_name,
		profit_before_tax_ksh_m,
		round(percent_rank() over (
	order by profit_before_tax_ksh_m), 2) as profit_percent_rank
	from
		cbk_profitability cp;
 
 --10.B Which banks are in the top 25%?
 select
	*
from
	(
	select
		bank_name,
		profit_before_tax_ksh_m,
		round(percent_rank() over (
	order by profit_before_tax_ksh_m), 2) as profit_percent_rank
	from
		cbk_profitability cp) as ranked
where
	ranked.profit_percent_rank >= 0.75
order by
	ranked.profit_percent_rank desc ; 
 
 -- PERCENT_RANK returns a value between 0 and 1 where 1 = highest value
-- Top 25% = percent_rank >= 0.75 

 
 --11. Using all three tables, for each bank show:
--Their asset rank globally 
--Their NPL ratio percentile 
--Whether their ROE improved or worsened compared to the previous bank ordered by assets using LAG()
--A column called overall_health using CASE WHEN:
--'Strong' if asset rank <= 5 AND NPL percentile <= 0.25
--'Vulnerable' if asset rank <= 5 AND NPL percentile > 0.25
--'Watch' if asset rank > 5 AND NPL percentile >= 0.75
--'Stable' otherwise
--Return bank_name, asset_rank, npl_percentile, prev_bank_roe, overall_health.
 select
	*,
	(case
			when ranked.return_on_equity_pct < ranked.prev_bank_roe then 'Worsened'
		when ranked.return_on_equity_pct > ranked.prev_bank_roe then 'Improved'
		ELSE 'No Change'
	END) as roe_bank_status,
	(case
		when ranked.asset_rank <= 5
		and ranked.npl_percentile <= 0.25 then 'Strong'
		when ranked.asset_rank <= 5
		and ranked.npl_percentile >0.25 then 'Vulnerable'
		when ranked.asset_rank >5
		and ranked.npl_percentile >= 0.75 then 'Watch'
		else 'Stable'
	end) as overall_health
from
	(
	select
		cms.bank_name,
		rank() over (
	order by
		cp.total_assets_ksh_m desc)as asset_rank,
		round(percent_rank() over(order by cnl.npl_ratio_dec24_pct), 2) as npl_percentile,
		cp.return_on_equity_pct,
		lag(cp.return_on_equity_pct, 1) over (
		order by return_on_equity_pct desc) as prev_bank_roe
	from
		cbk_market_share cms
	left join cbk_profitability cp on
		cms.bank_name = cp.bank_name
	left join cbk_npl_loans cnl on
		cms.bank_name = cnl.bank_name) as ranked;
 
 -- Results show 17 banks from cbk_market_share but significant data quality issues:

-- 1. Asset rank: rows 13-17 all show rank 13 (tied) instead of distinct ranks
--    This is because KCB, Absa, I&M, DTB, StanChart have NULL total_assets
--    from cbk_profitability due to bank name mismatches
--    RANK() treats NULL as equal, producing ties

-- 2. return_on_equity_pct and prev_bank_roe show NULL for 5 banks
--    Same cause — name mismatch between cbk_market_share and cbk_profitability
--    e.g. 'KCB Bank Kenya Limited' vs 'KCB Bank Kenya Ltd'

-- 3. npl_percentile shows 0 for most banks
--    Same name mismatch with cbk_npl_loans table

-- 4. overall_health classifications are unreliable due to NULL npl_percentile values
--    Most banks default to 'Strong' or 'Stable' because npl_percentile = 0

-- Conclusion: This query demonstrates the critical importance of a unique bank_id join key.
-- With clean data, this framework would provide meaningful health classifications.
