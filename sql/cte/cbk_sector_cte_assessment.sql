--SQL Assessment — CBK Banking Dataset


--1. Find all banks where their deposit market share is above the national average deposit share,
 	--but their NPL ratio has worsened from 2023 to 2024. Return bank name, deposit share, and NPL change.


with 
banks_above_avg_totaldeposit as (
select
	bank_name ,
	total_deposits_ksh_m as deposit_share,avg(cms.total_deposits_ksh_m ) over() as average
from
	cbk_market_share cms)
,
worsened_npl_ratio as (
select
	cnl.bank_name ,
	cnl.npl_ratio_dec23_pct ,
	cnl.npl_ratio_dec24_pct,
	cnl.npl_ratio_dec24_pct - cnl.npl_ratio_dec23_pct as NPL_change
from
	cbk_npl_loans cnl
where
	cnl.npl_ratio_dec24_pct > cnl.npl_ratio_dec23_pct	
		)
select
	banks_above_avg_totaldeposit.bank_name,
	banks_above_avg_totaldeposit.deposit_share,
	worsened_npl_ratio.Npl_change
from
	banks_above_avg_totaldeposit
join worsened_npl_ratio on
	banks_above_avg_totaldeposit.bank_name = worsened_npl_ratio.bank_name
	where banks_above_avg_totaldeposit.deposit_share > average ;

--There should be 5 banks but due to inconsistency only cooperative bank returns.

--2. For each peer group, identify the single best-performing bank by ROE. If there is a tie, both should appear. Return peer group, bank name, and ROE.

with data as (
select
		cms.bank_name ,
	cms.peer_group,
	cp.return_on_equity_pct as ROE,
	dense_rank() over(partition by cms.peer_group order by cp.return_on_equity_pct desc) as ranked_roe
from
	cbk_market_share cms
join cbk_profitability cp on
	cms.bank_name = cp.bank_name )
select
	bank_name,
	peer_group,
	ROE
from
	data
where
	data.ranked_roe = 1;

--3. Classify all banks into three liquidity tiers based on their capital adequacy ratio. 
	--Define your own thresholds and justify them in a comment. Return bank name, ratio, and your classification.

with banks_capital_tier as (
select
	bank_name,
	total_capital_to_rwa_pct as ratio,
	case
		when total_capital_to_rwa_pct >= 14.5 then 'Tier1-Well Capitalised'
		when total_capital_to_rwa_pct between 10.5 and 14.5 then 'Tier2-Adequately Capitalised'
		else 'Tier3-Undercapitalised'
	end as capitalised_status
from
		cbk_capital_adequacy cca)
select
	bank_name,
	ratio,
	capitalised_status
from
	banks_capital_tier ;

--The classification is based on the capital requirements of cbk.

--4. Find banks that rank in the top 5 by total assets but do NOT appear in the top 5 by profit before tax. Return bank name, asset rank, and profit rank.
with banks_ranked_by_assets as (
select
	cms.bank_name ,
	cms.total_assets_ksh_m ,
	rank() over(order by cms.total_assets_ksh_m desc) as asset_rank
from
	cbk_market_share cms),
banks_ranked_by_profit as (
select
	cp.bank_name ,
	cp.profit_before_tax_ksh_m ,
	rank() over(order by cp.profit_before_tax_ksh_m desc) as profit_rank
from
	cbk_profitability cp)
select
	banks_ranked_by_assets.bank_name,
	banks_ranked_by_assets.asset_rank,
	banks_ranked_by_profit.profit_rank
from
	banks_ranked_by_assets
left join banks_ranked_by_profit on
	banks_ranked_by_assets.bank_name = banks_ranked_by_profit.bank_name
where
	banks_ranked_by_assets.asset_rank <= 5 and (banks_ranked_by_profit.profit_rank > 5 or banks_ranked_by_profit.profit_rank is null) ;
	
--5. Calculate what percentage of total sector assets is controlled by Tier 1 banks from the health scorecard. Return a single value.
with health_scorecard as (
select
	cms.bank_name,
	cms.total_assets_ksh_m as assets, sum(cms.total_assets_ksh_m) over () as total_assets,
	CASE
		when cp.return_on_equity_pct < 0
		or cnl.npl_ratio_dec24_pct > 40 then 'Tier 4 - Distressed'
		when cp.return_on_equity_pct > 15
		and cnl.npl_ratio_dec24_pct < 10
		and cms.market_rank <= 10 then 'Tier 1 - Strong'
		when cp.return_on_equity_pct > 0
		and cnl.npl_ratio_dec24_pct < 20 then 'Tier 2 - Stable'
		when cp.return_on_equity_pct between 0 and 5
		or (cp.return_on_equity_pct > 0
		and cnl.npl_ratio_dec24_pct >= 20) then 'Tier 3 - Watch'
		when cp.return_on_equity_pct is null
		or cnl.npl_ratio_dec24_pct is null then 'No Data — Name Mismatch'
	end as Tier
from
		cbk_market_share cms
join cbk_profitability cp on
		cms.bank_name = cp.bank_name
join cbk_npl_loans cnl on
		cms.bank_name = cnl.bank_name)
select 
coalesce(sum(assets * 100 / total_assets ),0) as pct
from
	health_scorecard
	where Tier = 'Tier 1 - Strong'
;












