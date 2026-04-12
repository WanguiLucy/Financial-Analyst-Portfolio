/* Beginner — Single CTE

Using a CTE, calculate each bank's deposit share of the total sector, then filter for banks above 5%
Using a CTE, find the average NPL ratio for 2024, then return all banks above that average
Using a CTE, rank banks by total assets, then return only the top 10


Intermediate — Chained / Multiple CTEs

Using two CTEs, calculate average ROE per peer group in the first, then flag each bank as 'Above Average' or 'Below Average' relative to their peer group in the second
Using two CTEs, identify loss-making banks in the first CTE and capital-thin banks (shareholders_funds < 5,000M) in the second, then JOIN both to find banks that are both loss-making AND capital thin
Using a CTE, calculate each bank's NPL change from 2023 to 2024, then rank only the banks that worsened by deterioration speed


Advanced — CTEs replacing your existing subqueries

Rewrite the HHI query from Section 1 using a CTE instead of an inline subquery
Rewrite the top 5 deposit control query from Section 1 using a CTE — this time returning the bank names alongside the total percentage
Using three CTEs (profitability, NPL, capital), replicate the Section 4 tiering framework without any subqueries — all logic flows through CTEs into a final SELECT


Challenge

Using a recursive CTE, build the cumulative market share ladder — stopping at the bank that pushes the total past 80% */


--Section 1

--i. Using a CTE, calculate each bank's deposit share of the total sector, then filter for banks above 5%

with totaldeposit as (
select
	cms.bank_name,
	cms.total_deposits_ksh_m as total_deposits, (sum(total_deposits_ksh_m)  over () *0.05) as deposits
from
	cbk_market_share cms ) 
select
	bank_name,total_deposits
from
	totaldeposit where  total_deposits> deposits;

--ii. Using a CTE, find the average NPL ratio for 2024, then return all banks above that average
with average_npl_2024 as (
select
	cnl.bank_name ,
	cnl.npl_ratio_dec24_pct,
	avg(cnl.npl_ratio_dec24_pct) over () as avg_npl_ratio
from
	cbk_npl_loans cnl)
select
	bank_name,npl_ratio_dec24_pct
from
	average_npl_2024 npl_ratio
where
	npl_ratio_dec24_pct > avg_npl_ratio;

--iii. Using a CTE, rank banks by total assets, then return only the top 10
with ranked as (
select
	bank_name,
	cms.total_assets_ksh_m as total_assets,
	rank() over(order by cms.total_assets_ksh_m desc) as asset_rank
from
	cbk_market_share cms )
select
	bank_name,
	total_assets
from
	ranked
where asset_rank <=10;

--iv. Using two CTEs, calculate average ROE per peer group in the first, then flag each bank as 'Above Average' or 'Below Average' relative to their peer group in the second
with ROE_Average as (
select cms.bank_name, 
	cms.peer_group ,
	cp.return_on_equity_pct as roe,
	avg(cp.return_on_equity_pct) over(partition by cms.peer_group ) as avg_roe
from
	cbk_market_share cms
join cbk_profitability cp on
	cms.bank_name = cp.bank_name) ,
	ROE_Status as (
	select
		bank_name, peer_group,roe,
		case
			when roe > avg_roe then 'Above Average'
			when roe < avg_roe then 'Below Average'
			else 'Equal'
		end as classification
	from
		ROE_Average)
	select
		*
	from
		ROE_Status order by 2 desc; 


--v. Using two CTEs, identify loss-making banks in the first CTE and capital-thin banks (shareholders_funds < 5,000M) in the second, then JOIN both to find banks that are both loss-making AND capital thin
with loss_making as (
select
	cp.bank_name,
	cp.return_on_equity_pct as roe
from
	cbk_profitability cp
where
	return_on_equity_pct < 0 ),
capital_thin as (
select
	cms.bank_name ,
	cms.shareholders_funds_ksh_m as shareholders_funds
from
	cbk_market_share cms
where
	cms.shareholders_funds_ksh_m < 5000
	)
select
	*
from
	capital_thin
join loss_making on
	capital_thin.bank_name = loss_making.bank_name ;
		

--vi. Using a CTE, calculate each bank's NPL change from 2023 to 2024, then rank only the banks that worsened by deterioration speed

with npl_change as (
select
	cnl.bank_name ,
	cnl.npl_ratio_dec23_pct ,
	cnl.npl_ratio_dec24_pct ,
	(cnl.npl_ratio_dec24_pct - cnl.npl_ratio_dec23_pct ) as npl_diff
from
	cbk_npl_loans cnl where cnl.npl_ratio_dec23_pct < cnl.npl_ratio_dec24_pct ) /*is it this or reverse*/ ,
npl_change_ranked as (
select
	*,
	rank() over(order by npl_diff desc) as npl_diff_rank
from
	npl_change )
select
	*
from
	npl_change_ranked  ;

--vii. Rewrite the HHI query from Section 1 using a CTE instead of an inline subquery

with power_hhi as (
select
	cms.bank_name,
	cms.asset_market_share_pct,
	power(cms.asset_market_share_pct, 2 ) as pow2
from
	cbk_market_share cms),  
HHI_Index as (
select sum(pow2)as hhi_value,
	case
		when sum(pow2) < 1500 then 'Competitive'
		when sum(pow2) between 1500 and 2500 then 'Moderately Concentrated'
		Else 'Highly Concentrated'
	end as market_structure
from 
		power_hhi )
select
	*
from
	HHI_Index ;

--viii.Rewrite the top 5 deposit control query from Section 1 using a CTE — this time returning the bank names alongside the total percentage
with sector_total as (
    select sum(total_deposits_ksh_m) as total
    from cbk_market_share),
deposit_shares as (
    select cms.bank_name,
           cms.total_deposits_ksh_m,
           round(cms.total_deposits_ksh_m * 100 / st.total, 2) as percentage
    from cbk_market_share cms
    cross join sector_total st)/* why cross join?*/
select * from deposit_shares
order by 3 desc limit 5;

---ix.Using three CTEs (profitability, NPL, capital), replicate the Section 4 tiering framework without any subqueries — all logic flows through CTEs into a final SELECT
--section 4
/* The flagship output — classify every bank using ALL metrics combined:

Classification framework:
- 'Tier 1 — Strong'     : ROE > 15% AND NPL < 10% AND asset rank <= 10
- 'Tier 2 — Stable'     : ROE > 0% AND NPL < 20%
- 'Tier 3 — Watch'      : ROE > 0% BUT NPL >= 20% OR ROE between 0-5%
- 'Tier 4 — Distressed' : Negative ROE OR NPL > 40%

Additional flags:
- Capital thin flag: shareholders_funds < 5,000M
- NPL worsening flag: npl_ratio_dec24 > npl_ratio_dec23
- Size context: peer_group label

Final output per bank:
bank_name | tier | capital_flag | npl_trend | peer_group | asset_rank */


with Tier as (
select
	cms.bank_name,
	cms.shareholders_funds_ksh_m as share_funds,
	cnl.npl_ratio_dec24_pct,
	cnl.npl_ratio_dec23_pct,
	cms.peer_group, cms.total_assets_ksh_m as total_assets,
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
	end as tier_status
from
		cbk_market_share cms
left join cbk_profitability cp on
		cms.bank_name = cp.bank_name
left join cbk_npl_loans cnl on
		cms.bank_name = cnl.bank_name),
shareholders_flag as (
select
	*,
	case
		when Tier.share_funds < 5000 then 'Capital Thin'
		else 'Adequate'
	end as capital_flag,
	case
		when npl_ratio_dec24_pct > npl_ratio_dec23_pct then 'Worsening'
		when npl_ratio_dec24_pct < npl_ratio_dec23_pct then 'Improving'
		else 'Stable'
	end as npl_trend
from
	Tier ),
all_metrics as (
select
	bank_name,
	tier_status ,
	capital_flag,
	npl_trend,
	peer_group,
	rank() over(order by total_assets desc) as asset_rank
from
	shareholders_flag )
select
	*
from
	all_metrics ;


--x. Using a recursive CTE, build the cumulative market share ladder — stopping at the bank that pushes the total past 80%
WITH RECURSIVE ordered AS (
    SELECT
        bank_name,
        asset_market_share_pct,
        ROW_NUMBER() OVER (ORDER BY asset_market_share_pct DESC) AS rn
    FROM cbk_market_share
),
cumulative AS (
    SELECT
        bank_name,
        asset_market_share_pct,
        asset_market_share_pct AS cumulative_share,
        rn
    FROM ordered
    WHERE rn = 1

    UNION ALL

    SELECT
        o.bank_name,
        o.asset_market_share_pct,
        ROUND(c.cumulative_share + o.asset_market_share_pct, 2),
        o.rn
    FROM ordered o
    JOIN cumulative c ON o.rn = c.rn + 1
    WHERE c.cumulative_share < 80 )
SELECT
    bank_name,
    asset_market_share_pct,
    cumulative_share
FROM cumulative 
ORDER BY cumulative_share;


--Section 2

--i. Using a CTE, find all banks whose total_assets_ksh_m is above the sector average.
--Return bank_name, total_assets_ksh_m and sector_avg_assets.

with total_assets as (
select
	cms.bank_name ,
	cms.total_assets_ksh_m ,
	round(avg(cms.total_assets_ksh_m) over(),2) as sector_avg_assets
from
	cbk_market_share cms )
select
	*
from
	total_assets
where
	total_assets_ksh_m > sector_avg_assets;

--ii. Using a CTE, rank all banks by profit_before_tax_ksh_m and return only the top 10.
--Return bank_name, profit_before_tax_ksh_m and profit_rank.

with ranked_banks as( select cp.bank_name , cp.profit_before_tax_ksh_m , rank() over(order by cp.profit_before_tax_ksh_m desc) as profit_rank from cbk_profitability cp )
select
	*
from
	ranked_banks
where
	profit_rank <= 10;

--iii.CTE 1: Calculate average NPL ratio per peer group.
--CTE 2: Join that back to individual banks.
--Return each bank's name, peer group, their NPL ratio and their peer group average.
--Flag banks that are above their peer group average as 'Above Average' and below as 'Below Average'.
with average_banks_per_group as (
select
	cms.bank_name,
	cms.peer_group,
	cnl.npl_ratio_dec24_pct,
	round(avg(cnl.npl_ratio_dec24_pct) over(partition by cms.peer_group), 2) as avg_npl_ratio
from
	cbk_market_share cms
join cbk_npl_loans cnl on
	cms.bank_name = cnl.bank_name),
flagged_banks as (
select
	bank_name,
	case
		when npl_ratio_dec24_pct > avg_npl_ratio then 'Above Average'
		when npl_ratio_dec24_pct < avg_npl_ratio then 'Below Average'
		else 'No Change' end as bank_ratio_status
	from
		average_banks_per_group )
select
	*
from
	flagged_banks ;


---iv. Using a CTE, rewrite the Section 4 health scorecard from your banking project.
--The CTE should prepare the joined data first, then the outer query applies the CASE WHEN classification.
--Return bank_name, tier, capital_flag, npl_trend, peer_group, asset_rank.
with Tier as (
select
	cms.bank_name,
	cms.shareholders_funds_ksh_m as share_funds,
	cnl.npl_ratio_dec24_pct,
	cnl.npl_ratio_dec23_pct,
	cms.peer_group, cms.total_assets_ksh_m as total_assets,
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
	end as tier_status
from
		cbk_market_share cms
left join cbk_profitability cp on
		cms.bank_name = cp.bank_name
left join cbk_npl_loans cnl on
		cms.bank_name = cnl.bank_name),
shareholders_flag as (
select
	*,
	case
		when Tier.share_funds < 5000 then 'Capital Thin'
		else 'Adequate'
	end as capital_flag,
	case
		when npl_ratio_dec24_pct > npl_ratio_dec23_pct then 'Worsening'
		when npl_ratio_dec24_pct < npl_ratio_dec23_pct then 'Improving'
		else 'Stable'
	end as npl_trend
from
	Tier ),
all_metrics as (
select
	bank_name,
	tier_status ,
	capital_flag,
	npl_trend,
	peer_group,
	rank() over(order by total_assets desc) as asset_rank
from
	shareholders_flag )
select
	*
from
	all_metrics ;


--v.CTE 1: Get profitability data — bank_name, return_on_equity_pct, profit_before_tax_ksh_m
--CTE 2: Get capital data — bank_name, total_capital_to_rwa_pct, capital classification
--CTE 3: Join CTE 1 and CTE 2
--Return bank_name, return_on_equity_pct, total_capital_to_rwa_pct, capital_status
--Only show banks where ROE is positive AND capital is Well Capitalised

with profitability as (
select
	bank_name,
	return_on_equity_pct,
	profit_before_tax_ksh_m
from
	cbk_profitability cp),
capital as (
select
	cca.bank_name ,
	total_capital_to_rwa_pct,
	return_on_equity_pct,
	case
		when total_capital_to_rwa_pct >= 14.5 then 'Well Capitalised'
		when total_capital_to_rwa_pct between 10.5 and 14.5 then 'Adequately Capitalised'
		else 'Undercapitalised'
	end as capitalised_status
from
	cbk_capital_adequacy cca
left join profitability on
	cca.bank_name = profitability.bank_name ) ,
combined as (
select
	bank_name,
	return_on_equity_pct,
	total_capital_to_rwa_pct,
	capitalised_status
from
	capital
where
	return_on_equity_pct > 0
	and capitalised_status = 'Well Capitalised' )
select
	*
from
	combined ;


--vi. Using a CTE, calculate for each peer group:
/*
Total assets
Average ROE
Count of banks
Count of loss-making banks

Then in the outer query add a column called group_health:

'Healthy' if avg ROE > 10% AND loss-making count = 0
'Mixed' if avg ROE > 0% AND loss-making count > 0
'Distressed' if avg ROE <= 0% */
with loss_banks as (
select
	bank_name as bn,
	return_on_equity_pct
from
	cbk_profitability
where
	return_on_equity_pct < 0),
the_rest as (
select
	cms.peer_group,
	sum(cms.total_assets_ksh_m) as total_assets,
	avg(cp.return_on_equity_pct) as avg_roe,
	count(cms.bank_name) as number_of_banks,
	count(loss_banks.bn) as loss_making_count
from
	cbk_market_share cms
join cbk_profitability cp on
	cms.bank_name = cp.bank_name
left join loss_banks on
	cms.bank_name = loss_banks.bn
group by
	peer_group),
group_health as (
select
	*,
	case
		when avg_roe > 10
			and loss_making_count = 0 then 'Healthy'
			when avg_roe > 0
			and loss_making_count > 0 then 'Mixed'
			when avg_roe <= 0 then 'Distressed'
		end as bank_status
	from
		the_rest) 
select
	*
from
	group_health
;








