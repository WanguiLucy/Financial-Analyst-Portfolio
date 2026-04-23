-- ============================================================
-- Kenya Banking Sector Health Assessment — 2020 to 2024
-- Author: Lucy Wangui | BSc Applied Statistics, Maseno University
-- Data: CBK Bank Supervision Annual Reports (2020–2024)
-- Tools: SQLite · DB Browser for SQLite
-- GitHub: WanguiLucy
-- ============================================================

--Q01 Top 5 Banks by Total Assets (2024)
SELECT
	cms.bank_name ,
	cms.total_assets_ksh_m
FROM
	cbk_market_share cms
WHERE
	"year" = '2024'
ORDER BY
	cms.total_assets_ksh_m desc
limit 5 ;  

--Q02 Average NPL Ratio by Peer Group (2023)
SELECT
	cms.peer_group ,
	round(avg(cnl.npl_ratio_pct), 2) as avg_npl_ratio
FROM
	cbk_npl_loans cnl
JOIN cbk_market_share cms ON
	cnl.bank_name = cms.bank_name
WHERE
	cms."year" = '2023'
	and cnl."year" = '2023'
GROUP BY
	cms.peer_group;
	
--Q03 All Loss-Making Bank-Year Combinations
select
	cp."year" ,
	cp.bank_name ,
	cp.profit_before_tax_ksh_m as loss_amount
from
	cbk_profitability cp
where
	cp.profit_before_tax_ksh_m < 0
order by
	3 asc;	

--Q04 Year-by-Year Sector Gross Loan Growth

with lagged as (
select
	"year",
	bank_name,
	gross_loans_ksh_m,
	lag(gross_loans_ksh_m) over (partition by bank_name
order by
	"year") as prev_gross_loan
from
	cbk_npl_loans cnl 
)
select
	*,
	round((gross_loans_ksh_m - prev_gross_loan) * 100.0 / prev_gross_loan, 2) as yoy_pct_gross_change
from
	lagged
order by
	yoy_pct_gross_change desc;

--Q05 Banks Below Regulatory Capital Minimums
select
	cca."year" ,
	cca.bank_name ,
	case
		when cca.core_capital_to_rwa_pct >= 10.5
		and cca.total_capital_to_rwa_pct >= 14.5
		and cca.core_capital_to_deposits_pct >= 8 then 'Complies_to_all_3'
		when cca.core_capital_to_rwa_pct >= 10.5
		and cca.total_capital_to_rwa_pct < 14.5
		and cca.core_capital_to_deposits_pct < 8 then 'Complies_to_core_capital'
		when cca.core_capital_to_rwa_pct < 10.5
		and cca.total_capital_to_rwa_pct >= 14.5
		and cca.core_capital_to_deposits_pct < 8 then 'Complies_to_total_capital'
		when cca.core_capital_to_rwa_pct < 10.5
		and cca.total_capital_to_rwa_pct < 14.5
		and cca.core_capital_to_deposits_pct >= 8 then 'Complies_to_capitaldeposits'
		when cca.core_capital_to_rwa_pct >= 10.5
		and cca.total_capital_to_rwa_pct >= 14.5
		and cca.core_capital_to_deposits_pct < 8 then 'Both_corecapital_and_totalcapital'
		when cca.core_capital_to_rwa_pct >= 10.5
		and cca.total_capital_to_rwa_pct < 14.5
		and cca.core_capital_to_deposits_pct >= 8 then 'Both_corecapital_and_capitaldeposit'
		when cca.core_capital_to_rwa_pct < 10.5
		and cca.total_capital_to_rwa_pct >= 14.5
		and cca.core_capital_to_deposits_pct >= 8 then 'Both_totalcapital_and_capitaldeposits'
		else 'Does_not_comply_to_any'
	end as compliance_status
from
		cbk_capital_adequacy cca
where
	compliance_status != 'Complies_to_all_3'
	group by cca.bank_name ,
	cca."year" ;

--Q06 HHI Market Concentration Index by Year
select
	cms."year" ,
	round(sum(power(cms.asset_market_share_pct, 2)), 2) as HHI_Score,
	case
		when round(sum(power(cms.asset_market_share_pct, 2)), 2) < 1500 then 'Competitive'
		when round(sum(power(cms.asset_market_share_pct, 2)), 2) between 1500 and 2500 then 'Moderate'
		else 'Concentrated'
	end as market_structure_label
from
		cbk_market_share cms
group by
		cms."year" ;

--Q07 Profitability Tier Classification by Year
with ROE_Classification as (
select
	cp."year" ,
	cp.bank_name ,
	cp.return_on_equity_pct as ROE,
	case
		when cp.return_on_equity_pct >= 20 THEN 'Top Performer'
		when cp.return_on_equity_pct between 10 and 19.9 then 'Adequate'
		when cp.return_on_equity_pct between 0 and 9.9 then 'Low Performer'
		else 'Loss Making'
	end as ROE_Status
from
		cbk_profitability cp)
select
	"year" ,
	ROE_Status,
	COUNT(bank_name) as number_of_banks
from
	ROE_Classification
group by
	ROE_Status ,
	"year" ;

--Q08 Deposit Account Growth Rate by Peer Group
with general as (
select
	cms."year" ,
	cms.peer_group ,
	sum(case when cms.deposit_accounts is not null then cms.deposit_accounts end) as deposit_accounts
from
	cbk_market_share cms
group by
	cms.peer_group,
	cms."year"
order by
	cms."year"),
dep_acc_2020 as (
select
	"year" ,
	peer_group ,
	deposit_accounts as deposit_accounts_2020
from
	general
where
	"year" = '2020'),
dep_acc_2024 as (
select
	"year" ,
	peer_group ,
	deposit_accounts as deposit_accounts_2024
from
	general
where
	"year" = '2024')
select
	dep_acc_2020.peer_group ,
	deposit_accounts_2020 ,
	deposit_accounts_2024,
	round(power(cast(deposit_accounts_2024 as float) / deposit_accounts_2020 , 0.25) - 1, 2) as CAGR_pct
from
	dep_acc_2020
join dep_acc_2024 on
	dep_acc_2020.peer_group = dep_acc_2024.peer_group ;
/* CAGR - Compound Annual Growth Rate */

--Q09 NPL Ratio vs Loan Growth Risk Quadrant (2023)
with sector_avg as (
select
	round(avg(loan_growth_pct), 2) as avg_loan_growth,
	round(avg(npl_ratio_pct), 2) as avg_npl_ratio
from
	cbk_npl_loans)
select
	cnl.bank_name, cms.peer_group ,
	loan_growth_pct,
	npl_ratio_pct,
		case
		when loan_growth_pct > avg_loan_growth
		and npl_ratio_pct > avg_npl_ratio then 'Aggressive Risk'
		when loan_growth_pct > avg_loan_growth
		and npl_ratio_pct < avg_npl_ratio then 'Healthy Expansion'
		when loan_growth_pct < avg_loan_growth 
		and npl_ratio_pct > avg_npl_ratio then 'Stressed'
		else 'Conservative'
	end as risk_quadrants
from
		cbk_npl_loans cnl join cbk_market_share cms on cnl.bank_name = cms.bank_name ,
	sector_avg
where
	cnl."year"  = '2023' and cms."year" = '2023'
;

--Q10 Capital Adequacy Compliance Scorecard (All Years)
select
	cca."year" ,
	cca.bank_name ,
	case
		when cca.core_capital_to_rwa_pct >= 10.5
		and cca.total_capital_to_rwa_pct >= 14.5
		and cca.core_capital_to_deposits_pct >= 8 then 'Passed_all_3'
		when cca.core_capital_to_rwa_pct >= 10.5
		and cca.total_capital_to_rwa_pct < 14.5
		and cca.core_capital_to_deposits_pct < 8 then 'Passed_core_capital_1'
		when cca.core_capital_to_rwa_pct < 10.5
		and cca.total_capital_to_rwa_pct >= 14.5
		and cca.core_capital_to_deposits_pct < 8 then 'Passed_total_capital_1'
		when cca.core_capital_to_rwa_pct < 10.5
		and cca.total_capital_to_rwa_pct < 14.5
		and cca.core_capital_to_deposits_pct >= 8 then 'Passed_capitaldeposits_1'
		when cca.core_capital_to_rwa_pct >= 10.5
		and cca.total_capital_to_rwa_pct >= 14.5
		and cca.core_capital_to_deposits_pct < 8 then 'Passed_corecapital_and_totalcapital_2'
		when cca.core_capital_to_rwa_pct >= 10.5
		and cca.total_capital_to_rwa_pct < 14.5
		and cca.core_capital_to_deposits_pct >= 8 then 'Passed_corecapital_and_capitaldeposit_2'
		when cca.core_capital_to_rwa_pct < 10.5
		and cca.total_capital_to_rwa_pct >= 14.5
		and cca.core_capital_to_deposits_pct >= 8 then 'Passed_totalcapital_and_capitaldeposits_2'
		else 'Failed_all_3'
	end as compliance_status
from
		cbk_capital_adequacy cca group by cca.bank_name, cca."year" ;

--Q11 Sector-Wide Return on Equity Trend (Peer Group Level)
select
	cms."year" ,
	cms.peer_group,
	round(avg(cp.return_on_equity_pct), 2) as avg_ROE
from
	cbk_market_share cms
join cbk_profitability cp on
	cms.bank_name = cp.bank_name and cms."year" = cp."year" 
group by
	cms."year",
	cms.peer_group ;

--Q12 YoY ROA Change — Top Improvers and Deteriorators
select
	cp."year" ,
	cms.peer_group ,
	cp.bank_name ,
	cp.return_on_assets_pct as ROA,
	lag(cp.return_on_assets_pct) over(partition by cp.bank_name order by cp."year" ) as prev_ROA,
	round((cp.return_on_assets_pct - lag(cp.return_on_assets_pct) over(partition by cp.bank_name order by cp."year")) * 100 / lag(cp.return_on_assets_pct) over(partition by cp.bank_name order by cp."year"), 2) as yoy_ROA_change_pct
from
	cbk_profitability cp
join cbk_market_share cms on
	cp.bank_name = cms.bank_name
	and cp."year" = cms."year"
 ;

--Q13 Rolling 3-Year Average NPL Ratio per Bank
with rolling_3yr_ratio as (
select
	cnl."year" ,
	cnl.bank_name,
	cnl.npl_ratio_pct,
	round(AVG(cnl.npl_ratio_pct) OVER (PARTITION BY bank_name
ORDER BY
	cnl."year" ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as rolling_3
from
	cbk_npl_loans cnl)
select
	*,
	case
		when rolling_3 > npl_ratio_pct then 'Improving'
		when rolling_3 < npl_ratio_pct then 'Worsening'
		else 'No Change'
	end as Status
from
	rolling_3yr_ratio;

--Q14 Bank Asset Rank Shift: 2020 to 2024
with ranks_2020 as (
select
	cms."year" ,
	cms.bank_name ,
	cms.total_assets_ksh_m as assets_2020,
	rank() over(partition by cms."year" order by cms.total_assets_ksh_m desc) as assets_rank_2020
from
	cbk_market_share cms
where
	"year" = '2020'),
ranks_2024 as(select
	cms."year" ,
	cms.bank_name ,
	cms.total_assets_ksh_m as assets_2024,
	rank() over(partition by cms."year" order by cms.total_assets_ksh_m desc) as assets_rank_2024
from
	cbk_market_share cms
where
	"year" = '2024')
select
	r0.bank_name ,
	r0.assets_2020 ,
	r4.assets_2024,
	r0.assets_rank_2020,
	r4.assets_rank_2024,
	r0.assets_rank_2020 - r4.assets_rank_2024 as asset_rank_diff,
	case
		when r0.assets_rank_2020 > r4.assets_rank_2024 then 'Climbed'
		when r0.assets_rank_2020 < r4.assets_rank_2024 then 'Fell'
		else 'Stable'
	end as rank_status
from
		ranks_2020 r0
join ranks_2024 r4 on
		r0.bank_name = r4.bank_name; 

--Q15 Loan-to-Deposit Ratio Analysis by Bank and Year
select
	cnl."year" ,
	cnl.bank_name,
	cnl.gross_loans_ksh_m ,
	cms.total_deposits_ksh_m,
	round((cnl.gross_loans_ksh_m * 100 / cms.total_deposits_ksh_m ), 2) as LDR_pct,
	case
		when round((cnl.gross_loans_ksh_m * 100 / cms.total_deposits_ksh_m ), 2) > 110 then 'Very High'
		when round((cnl.gross_loans_ksh_m * 100 / cms.total_deposits_ksh_m ), 2) between 90 and 110 then 'High'
		when round((cnl.gross_loans_ksh_m * 100 / cms.total_deposits_ksh_m ), 2) between 70 and 90 then 'Optimal'
		else 'Low'
	end as LDR_Risk,
	case
		when round((cnl.gross_loans_ksh_m * 100 / cms.total_deposits_ksh_m ), 2) > 90 then 'Above 90'
		else 'Below 90'
	end as crossed_flag
from
		cbk_market_share cms
join cbk_npl_loans cnl on
		cms.bank_name = cnl.bank_name
	and cms."year" = cnl."year" ;

--Q16 NPL Coverage Ratio Estimation
with bad_loan_coverage as (
select
	cnl."year" ,
	cnl.bank_name ,
	cca.core_capital_ksh_m as core_capital ,
	cnl.gross_loans_ksh_m as gross_loans ,
	round((cca.core_capital_ksh_m * 100 / cnl.gross_loans_ksh_m ), 2) as capital_to_loans_buffer
from
	cbk_npl_loans cnl
join cbk_capital_adequacy cca on
	cca.bank_name = cnl.bank_name and cca."year" = cnl."year" )
select
	*,
	rank() over(partition by "year" order by capital_to_loans_buffer desc) as coverage_rank,
	case
		when gross_loans > core_capital then 'Insufficient Capital Coverage'
		when gross_loans < core_capital then 'Sufficient Capital Coverage'
		else 'No Coverage Needed'
	end as capital_at_risk_flag
from
		bad_loan_coverage group by bank_name, "year" ; 

--Q17 Concentration Risk: Top 5 Banks' Share Over Time
with ranked as (
select
	cms."year" ,
	cms.bank_name ,
	cms.total_assets_ksh_m ,
	rank() over (partition by cms."year"
order by
	cms.total_assets_ksh_m desc) as assets_rank
from
	cbk_market_share cms
group by
	cms.bank_name ,
	"year"),
ranked_5 as (
select
	*
from
	ranked
where
	assets_rank <= 5)
select
	"year" ,
	sum(total_assets_ksh_m) as total_assets,
	lag(sum(total_assets_ksh_m)) over(order by "year" ) as prev_total_assets,
	case
		when sum(total_assets_ksh_m) > lag(sum(total_assets_ksh_m)) over(order by "year" ) then 'Rising'
		when sum(total_assets_ksh_m) < lag(sum(total_assets_ksh_m)) over(order by "year" ) then 'Dropping'
		else 'Stable'
	end as change_status
from
		ranked_5
group by
		"year" ;

--Q18 Composite Bank Health Score (All Four Datasets)
with
size_score as (
select
		bank_name,
		(asset_market_share_pct - min(asset_market_share_pct) over())
      / nullif(max(asset_market_share_pct) over() - min(asset_market_share_pct) over(), 0) as norm_size
from
		cbk_market_share
where
		year = '2023'
),
	credit_score as (
select
		bank_name,
		1.0 - (npl_ratio_pct - min(npl_ratio_pct) over())
      / nullif(max(npl_ratio_pct) over() - min(npl_ratio_pct) over(), 0) as norm_credit
from
		cbk_npl_loans
where
		year = '2023'
),
	profit_score as (
select
		bank_name,
		(return_on_assets_pct - min(return_on_assets_pct) over())
      / nullif(max(return_on_assets_pct) over() - min(return_on_assets_pct) over(), 0) as norm_profit
from
		cbk_profitability
where
		"year" = '2023'
),
	capital_score as (
select
	bank_name,
	(cca.core_capital_to_rwa_pct - min(cca.core_capital_to_rwa_pct) over()) 
	/ nullif(max(cca.core_capital_to_rwa_pct) over() - min(cca.core_capital_to_rwa_pct) over(), 0) as norm_capital
from
	cbk_capital_adequacy cca
where
	"year" = '2023')
select
	s.bank_name,
	round(s.norm_size, 3) as size_score,
	round(c.norm_credit, 3) as credit_score,
	round(p.norm_profit, 3) as profit_score,
	round(cs.norm_capital,3) as capital_score,
	round((s.norm_size + c.norm_credit + p.norm_profit + cs.norm_capital) / 4.0, 3) as composite_score,
	rank() over (
order by
	(s.norm_size + c.norm_credit + p.norm_profit + cs.norm_capital) / 4.0 desc) as health_rank
from
	size_score s
left join credit_score c on
	s.bank_name = c.bank_name
left join profit_score p on
	s.bank_name = p.bank_name
left join capital_score cs on
	s.bank_name = cs.bank_name
order by
	composite_score desc;

--Q19 Identifying and Tracking Systemically Important Banks (SIBs)
with
median_capital as (
select
	avg(core_capital_to_rwa_pct) as sector_median
from
	(
	select
		core_capital_to_rwa_pct
	from
		cbk_capital_adequacy
	where
		"year" = '2023'
		and core_capital_to_rwa_pct is not null
	order by
		core_capital_to_rwa_pct
	limit 2 - (
	select
		count(*)
	from
		cbk_capital_adequacy
	where
		"year" = '2023'
		and core_capital_to_rwa_pct is not null) % 2
    offset (
	select
		(count(*) - 1) / 2
	from
		cbk_capital_adequacy
	where
		"year" = '2023'
		and core_capital_to_rwa_pct is not null)
  )
),
sib_flags as (
select
	cms."year",
	cms.bank_name,
	cms.asset_market_share_pct,
	cca.core_capital_to_rwa_pct,
	case
		when cms.asset_market_share_pct > 5
			and cca.core_capital_to_rwa_pct > sector_median 
         then 1
			else 0
		end as is_sib
	from
		cbk_market_share cms
	join cbk_capital_adequacy cca on
		cms.bank_name = cca.bank_name
		and cms."year" = cca."year",
		median_capital
	where
		cms."year" in ('2023', '2024')
)
select
	"year",
	bank_name,
	is_sib,
	case
		when is_sib = 1
		and lag(is_sib) over (partition by bank_name
	order by
		year) = 1 then 'retained'
		when is_sib = 1
		and lag(is_sib) over (partition by bank_name
	order by
		year) = 0 then 'gained'
		when is_sib = 0
		and lag(is_sib) over (partition by bank_name
	order by
		year) = 1 then 'lost'
		else 'n/a'
	end as sib_status
from
	sib_flags
order by
	bank_name,
	"year";

  
--Q20 Full Sector Stress Index — 2020 to 2024
with
high_npl as (
select
	"year" ,
	round(count(case when npl_ratio_pct > 15 then 1 end) * 100.0 / count(*), 2) as pct_high_npl
from
	cbk_npl_loans
group by
	"year" 
),
loss_banks as (
select
	"year" ,
	round(count(case when profit_before_tax_ksh_m < 0 then 1 end) * 100.0 / count(*), 2) as pct_loss
from
	cbk_profitability
group by
	"year" 
),
core_capital as (
select
	cca."year" ,
	round(count(case when core_capital_to_rwa_pct >= 10.5 then 1 end) * 100.0 / count(*), 2) as capital_score
from
	cbk_capital_adequacy cca
group by
	"year" ),
hhi as (
select
	year,
	sum(power(asset_market_share_pct, 2)) as hhi_score
from
	cbk_market_share
group by
	"year" 
),
combined as (
select
	h.year,
	h.pct_high_npl,
	l.pct_loss,
	cs.capital_score,
	hhi.hhi_score
from
	high_npl h
join loss_banks l on
	h."year" = l."year"
join core_capital cs on
	h."year" = cs."year"
join hhi on
	h."year" = hhi."year" 
)
select
	year,
	pct_high_npl,
	pct_loss,
	capital_score,
	round(hhi_score, 2) as hhi_score,
	round((
   1 - ((pct_high_npl - min(pct_high_npl) over()) / nullif(max(pct_high_npl) over() - min(pct_high_npl) over(), 0))
    + 1 - ((pct_loss - min(pct_loss) over()) / nullif(max(pct_loss) over() - min(pct_loss) over(), 0)) 
    + (capital_score - min(capital_score) over()) / nullif(max(capital_score) over() - min(capital_score) over(), 0)
    + 1- ((hhi_score - min(hhi_score) over()) / nullif(max(hhi_score) over() - min(hhi_score) over(), 0))
  ) / 4.0, 3) as stress_index
from
	combined
order by
	"year" ;


