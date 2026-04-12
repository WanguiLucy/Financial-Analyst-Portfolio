-- ============================================================
-- Kenya Banking Sector Health Assessment 2024
-- Author: Lucy Wangui | BSc Statistics, Maseno University | 2026
-- Data: Central Bank of Kenya Banking Supervision Report 2024
-- Tools: PostgreSQL, DBeaver
-- ============================================================


--Section 1

/*Questions to answer:
- What is the asset distribution across peer groups?
- How concentrated is the market? (HHI — Herfindahl index using SUM of squared market shares)
- What percentage of total deposits do the top 5 banks control?
- Running market share cumulative — at what point do you hit 80% of sector assets?*/


--i. What is the asset distribution across peer groups?
select
	peer_group,
	sum(cms.total_assets_ksh_m) as total_assets,
	round(sum(cms.total_assets_ksh_m)* 100 /(select sum(cbk_market_share.total_assets_ksh_m) from cbk_market_share), 2)as pct_per_sector
from
	cbk_market_share cms
group by
	1;


--ii. How concentrated is the market? 

select
	round(sum(power(asset_market_share_pct, 2)), 2) as hhi_index,
	case
		when sum(power(asset_market_share_pct, 2))<1500 then 'Competitive' when sum(power(asset_market_share_pct,2)) between  1500  and  2500  then ' Moderately concentrated' else ' Highly Concentrated'
	end as market_structure
from
		cbk_market_share;

-- HHI Result: 807 — Competitive market structure
-- Despite competitive classification, top 5 banks control 59.28% of sector assets
-- This gap between HHI and cumulative concentration is the key finding
-- HHI measures structural dominance — no single bank is dominant enough to skew it
-- But cumulative share shows practical concentration is significant
-- CBK should monitor both metrics as dual indicators of market health
-- Scale: <1500 Competitive | 1500-2500 Moderate | >2500 Highly Concentrated | 10000 Pure Monopoly


--iii. What percentage of total deposits do the top 5 banks control?
select 
	round(sum(percentages), 2) as top_5_deposit_control_pct
from
	(
	select
		bank_name,
		total_deposits_ksh_m,
		total_deposits_ksh_m * 100 / (
		select
			sum(total_deposits_ksh_m)
		from
			cbk_market_share cms ) as percentages
	from
		cbk_market_share cms2
	order by
		2 desc
	limit 5) as top_5 
;

-- Top 5 banks control 59.28% of total sector deposits
-- These are: [KCB, Equity, Co-op, NCBA, ABSA] — same banks dominating assets
-- Deposit concentration mirrors asset concentration — systemic risk is real

--iv. Running market share cumulative — at what point do you hit 80% of sector assets?
select
	sub.bank_name ,
	asset_market_share_pct,
	market_cumulative_share
from
	(
	select
		bank_name,
		cms.asset_market_share_pct ,
		round(sum(cms.asset_market_share_pct) over(order by cms.asset_market_share_pct desc), 2) as market_cumulative_share
	from
		cbk_market_share cms) sub
where
	market_cumulative_share <= 80
order by
	3 ;
-- Only 10 out of 17 banks account for 80% of sector assets
-- The remaining 7 banks share just 20% of assets between them
-- This confirms significant asset concentration in Kenya's banking sector despite the HHI classifying it as Competitive


 --Section 2
  
 
 /*Questions to answer:
- Rank all banks by ROE and ROA — who leads each metric?
- Which banks are loss-making? What percentage of the sector does this represent?
- Is there a correlation between bank size (assets) and profitability (ROE)?
- Which peer group generates the highest average profit margin?
- Quartile analysis — which quartile does each bank fall into by profitability?*/


 
--i. Rank all banks by ROE and ROA — who leads each metric?
select
	bank_name,
	return_on_equity_pct,
	rank() over(order by return_on_equity_pct desc ) roe_rank,
	cp.return_on_assets_pct,
	rank() over( order by cp.return_on_assets_pct desc) roa_rank
from
	cbk_profitability cp ;
 
 
 --ii. Which banks are loss-making? What percentage of the sector does this represent?
select
	count(bank_name) as loss_making_banks,
	count(bank_name) * 100 /(
	select
		count(bank_name)
	from
		cbk_profitability) as pct_loss_making_banks
from
	cbk_profitability cp
where
	cp.profit_before_tax_ksh_m <0 ;

--iii. percentage of total sector profit that is loss 
 select round(sum(sub.profit_before_tax_ksh_m ) *100 /(select sum(profit_before_tax_ksh_m) from cbk_profitability ) ,2) as total_loss_pct
 from (select
	bank_name,
	cp.profit_before_tax_ksh_m  
from
	cbk_profitability cp
where
	cp.profit_before_tax_ksh_m <0
order by
	cp.profit_before_tax_ksh_m desc)sub ;
-- Result is negative because losses reduce total sector profit
-- 10 out of 39 banks (25%) are loss-making in 2024
-- However their combined losses represent only -4% of total sector profit
-- This means the profitable banks are generating enough to absorb the losses
-- The sector is profitable overall despite 1 in 4 banks losing money
-- Risk is concentrated in smaller banks — large banks remain profitable

 --iv. Is there a correlation between bank size (assets) and profitability (ROE)?
  select
	bank_name,
	cp.total_assets_ksh_m ,
	cp.return_on_equity_pct,
	rank() over(order by cp.return_on_equity_pct desc ) as roe_rank
from
	cbk_profitability cp
order by
	2 desc;
 
 -- No consistent correlation between asset size and ROE
-- From roe:Large asset does not guarantee high ROE
-- e.g. Equity (2nd largest) has lower ROE than Citibank (much smaller)
-- Citibank's high ROE despite small size suggests superior operational efficiency
 -- Size rank and ROE rank frequently diverge — efficiency matters more than scale

 
 --v. Which peer group generates the highest average profit margin?
select
	cms.peer_group ,
	avg(cp.profit_before_tax_ksh_m) as avg_profit_margin
from
	cbk_market_share cms
join cbk_profitability cp on
	cms.bank_name = cp.bank_name
group by
	1
order by
	2 desc
;
-- Large peer group generates 7x higher average profit than Medium peer group
-- Large banks avg profit: KSh 24,382M vs Medium banks: KSh 3,326M
-- This gap is driven by scale advantages — larger loan books, more deposit accounts and stronger brand recognition driving customer volumes
-- JOIN on bank_name reduces sample size due to name inconsistencies
-- Results directionally correct but exact figures may shift with clean data
 
-- vi. How do Large vs Medium banks compare across all profitability metrics? 
SELECT
    cms.peer_group,
    AVG(cp.profit_before_tax_ksh_m) AS avg_absolute_profit,
    AVG(cp.return_on_assets_pct) AS avg_roa,
    AVG(cp.return_on_equity_pct) AS avg_roe
FROM cbk_market_share cms
JOIN cbk_profitability cp ON cms.bank_name = cp.bank_name
GROUP BY 1
ORDER BY 2 DESC;
-- Large banks outperform Medium banks on every profitability metric
-- Large banks: Avg ROA 3.725% | Avg ROE 23.775%
-- Medium banks: Avg ROA 1.8%  | Avg ROE -0.8625%
-- Medium banks show NEGATIVE average ROE — destroying shareholder value on average
-- This means the loss-making Medium banks are dragging the group average below zero
-- Large banks are not just bigger — they are genuinely more efficient and profitable
-- Scale advantages in banking are real and significant in Kenya's sector
-- Medium bank negative ROE is heavily influenced by Ecobank (-90.9%) and Access Bank (-159%)
-- These two outliers pull the Medium group average into negative territory


 --vii. Quartile analysis — which quartile does each bank fall into by profitability?
select
	cp.bank_name ,
	ntile(4) over(order by cp.profit_before_tax_ksh_m ) as quartiles
from
	cbk_profitability cp ;

-- Quartile 1: Bottom 25% — most loss-making or least profitable banks
-- Quartile 2: Lower middle 25%
-- Quartile 3: Upper middle 25%
-- Quartile 4: Top 25% — most profitable banks
 
  --section 3 
 
 /* Questions to answer:

-Which banks have NPL ratios above CBK's 5% benchmark? How many?
- Which banks improved NPL ratios from 2023 to 2024? Which worsened?
- What is the sector average NPL ratio weighted by loan book size?
- Rank banks by NPL deterioration — who got worse the fastest?
- Is there a relationship between bank size and NPL ratio?
- (Large banks — are they better or worse than Medium banks on average?) */
 
 --i. Which banks have NPL ratios above CBK's 5% benchmark? How many? 
 
select
	bank_name,
	cnl.npl_ratio_dec24_pct,
	count(*) over() as total_above_benchmark
from
	cbk_npl_loans cnl
where
	cnl.npl_ratio_dec24_pct >5 ;

-- 37 out of 38 banks exceed CBK's 5% NPL benchmark
-- Only 1 bank is within the acceptable range


--ii. Which banks improved NPL ratios from 2023 to 2024? Which worsened?
select
	cnl.bank_name ,
	cnl.npl_ratio_dec23_pct ,
	cnl.npl_ratio_dec24_pct,
	case
		when cnl.npl_ratio_dec23_pct > cnl.npl_ratio_dec24_pct then 'Improved'
		when cnl.npl_ratio_dec23_pct < cnl.npl_ratio_dec24_pct then 'Worsened'
		else 'No Change'
	end as npl_status
from
		cbk_npl_loans cnl
order by
		3 desc ;
-- 22 banks worsened, 15 improved, 1 no change
-- More than half the sector saw NPL ratios deteriorate in 2024
-- Credit Bank Plc worst at 59.6% NPL 
-- UBA Kenya Bank Kenya L best performer — improved from 20.9% to 6.5%
 
 --iii. What is the sector average NPL ratio weighted by loan book size?
 select
	round(sum(cnl.npl_ratio_dec23_pct * cnl.gross_loans_dec23_ksh_m )/ sum(cnl.gross_loans_dec23_ksh_m), 2) as weighted_avg_npl_2023,
	round(sum(cnl.npl_ratio_dec24_pct * cnl.gross_loans_dec24_ksh_m )/ sum(cnl.gross_loans_dec24_ksh_m), 2) as weighted_avg_npl_2024
from
	cbk_npl_loans cnl ;

--Sector weighted avg NPL rose from 15.52% (2023) to 17.11% (2024)
-- Weighted by loan book size so reflects true sector credit risk exposure
-- A 1.59 percentage point deterioration in one year is significant
-- Simple average would overweight small banks — weighted average is more accurate
-- Weighted average weights each bank's NPL by its loan book size
-- Simple average treats a KSh 10B and KSh 1T loan book equally — misleading
-- Weighted average reflects the true sector-wide credit risk exposure 
 
 
 
 --iv. Rank banks by NPL deterioration — who got worse the fastest?
select
	cnl.bank_name ,
	cnl.npl_ratio_dec23_pct ,
	cnl.npl_ratio_dec24_pct,
	(cnl.npl_ratio_dec24_pct - cnl.npl_ratio_dec23_pct) as npl_change
from
		cbk_npl_loans cnl
where
	cnl.npl_ratio_dec23_pct < cnl.npl_ratio_dec24_pct
order by
	4 desc; 
 -- Ranked by absolute point change, not percentage change
--Guaranty Trust Bank deteriorated fastest — NPL jumped 23 points from 32.8% to 55.8% in one year — more than half its loans now non-performing
-- Credit Bank Plc at 59.6% is the highest absolute NPL in the sector
-- Top 5 fastest deteriorating banks all saw NPL rise by more than 9 points in one year
 
 
 --v. Is there a relationship between bank size and NPL ratio?
 
 select
	cms.bank_name,
	cms.total_assets_ksh_m ,rank() over(order by cms.total_assets_ksh_m desc ) as size_rank,
	cnl.npl_ratio_dec24_pct,rank() over(order by cnl.npl_ratio_dec24_pct ) as npl_rank
from
	cbk_market_share cms
join cbk_npl_loans cnl on
	cms.bank_name = cnl.bank_name
order by
	2 desc;
-- No clear relationship between bank size and NPL ratio
-- Co-operative Bank (size rank 1) has NPL rank 7 — large but poor loan quality
-- Citibank (size rank 4) has NPL rank 1 — best loan quality despite smaller size
-- Standard Chartered (size rank 2) has NPL rank 2 — size and quality aligned
-- Loan quality is driven by credit risk management, not bank size
 
 
 --vi. (Large banks — are they better or worse than Medium banks on average?)
  select
	cms.peer_group ,
	round(avg(cms.total_assets_ksh_m),2) as avg_assets,
	round(avg(cnl.npl_ratio_dec24_pct),2) as avg_npl_ratio_2024
from
	cbk_market_share cms
join cbk_npl_loans cnl on
	cms.bank_name = cnl.bank_name
	group by 1;
-- Medium banks have higher average NPL (14.03%) than Large banks (12.05%)
-- Despite having smaller loan books, Medium banks carry proportionally more bad loans
-- Large banks benefit from more sophisticated credit risk management systems
-- However both peer groups far exceed CBK's 5% benchmark
-- The entire sector requires attention, not just specific peer groups 
 
 
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

select
	cms.bank_name,
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
	end as Tier,
	case
		when cms.shareholders_funds_ksh_m < 5000 then 'Capital Thin'
		else 'Adequate'
	end as capital_flag,
	case
		when cnl.npl_ratio_dec24_pct > cnl.npl_ratio_dec23_pct then 'Worsening'
		when cnl.npl_ratio_dec24_pct < cnl.npl_ratio_dec23_pct then 'Improving'
		else 'Stable'
	end as npl_trend,
	cms.peer_group ,
	rank() over(order by cms.total_assets_ksh_m desc) as asset_rank
from
		cbk_market_share cms
left join cbk_profitability cp on
		cms.bank_name = cp.bank_name
left join cbk_npl_loans cnl on
		cms.bank_name = cnl.bank_name ;

-- Tier 1 Strong: 0 banks — name mismatch prevents Large bank classification
-- Tier 2 Stable: 5 banks (Prime, Citibank, Family, Bank of India, cooperative bank of kenya ltd)
-- Tier 3 Watch: 1 bank (National Bank of Kenya)
-- Tier 4 Distressed: 2 banks (Ecobank, SBM Bank)
-- No Data-Name Mismatch: 9 banks — due to bank_name inconsistencies across tables


--Section 5

/*Questions to answer:
1. Rank all banks by core_capital_ksh_m — who has the strongest capital base?

2. Which banks are below CBK's minimum capital ratios?
   - core_capital_to_rwa_pct < 10.5% (CBK minimum)
   - total_capital_to_rwa_pct < 14.5% (CBK minimum)
   - core_capital_to_deposits_pct < 8% (CBK minimum)

3. Classify each bank as:
   - 'Well Capitalised' if total_capital_to_rwa_pct >= 14.5%
   - 'Adequately Capitalised' if between 10.5% and 14.5%
   - 'Undercapitalised' if below 10.5%

4. For each bank calculate the capital buffer above CBK minimum:
   (total_capital_to_rwa_pct - 14.5) as capital_buffer
 
5. Quartile analysis — which quartile does each bank fall into
   by total_capital_to_rwa_pct?

6. Which banks have negative core_capital_to_deposits_pct? */


--i. Rank all banks by core_capital_ksh_m — who has the strongest capital base?
select
	cca.bank_name ,
	cca.core_capital_ksh_m,
	rank() over(order by cca.core_capital_ksh_m desc) as core_capital_rank
from
	cbk_capital_adequacy cca ;
-- KCB leads with KSh 144,770M core capital — strongest buffer in the sector
-- Top 3: KCB, Equity, Co-op — same banks that dominate assets and deposits

--ii. Which banks are below CBK's minimum capital ratios?
-- core_capital_to_rwa_pct < 10.5% (CBK minimum)
-- total_capital_to_rwa_pct < 14.5% (CBK minimum)
-- core_capital_to_deposits_pct < 8% (CBK minimum)
select
	bank_name,
	core_capital_to_rwa_pct, cca.total_capital_to_rwa_pct ,
	cca.core_capital_to_deposits_pct
from
	cbk_capital_adequacy cca
where
	core_capital_to_rwa_pct < 10.5
	or total_capital_to_rwa_pct < 14.5
	or core_capital_to_deposits_pct < 8  ;
--shows 6 banks that violated/breached the minimum requirement 
-- Breaching core_capital_to_deposits is the most serious — it signals inability to cover depositor obligations

--iii.Classify each bank as:
   	-- 'Well Capitalised' if total_capital_to_rwa_pct >= 14.5%
  	-- 'Adequately Capitalised' if between 10.5% and 14.5%
   	-- 'Undercapitalised' if below 10.5%

select
	bank_name,
	total_capital_to_rwa_pct,
	case
		when total_capital_to_rwa_pct >= 14.5 then 'Well Capitalised'
		when total_capital_to_rwa_pct between 10.5 and 14.5 then 'Adequately Capitalised'
		else 'Undercapitalised'
	end as capitalised_status
from
		cbk_capital_adequacy cca
order by
	2 desc;


--iv.For each bank calculate the capital buffer above CBK minimum:
-- (total_capital_to_rwa_pct - 14.5) as capital_buffer
 select
	bank_name,
	total_capital_to_rwa_pct,
	total_capital_to_rwa_pct - 14.5 as capital_buffer
from
	cbk_capital_adequacy cca ;

-- Positive buffer = excess capital above regulatory minimum
-- Bank of India has the largest buffer (85.3% - 14.5% = +70.8 points)


--v. Quartile analysis — which quartile does each bank fall into by total_capital_to_rwa_pct?
select
	cca.bank_name ,
	cca.total_capital_to_rwa_pct,
	ntile(4) over(order by cca.total_capital_to_rwa_pct desc) as quartiles
from
	cbk_capital_adequacy cca;
-- Quartile 1: Most capitalised banks — strongest regulatory buffer
-- Quartile 4: Least capitalised — closest to or breaching minimums

--vi. Which banks have negative core_capital_to_deposits_pct?
select
	bank_name,
	cca.core_capital_to_deposits_pct
from
	cbk_capital_adequacy cca
where
	cca.core_capital_to_deposits_pct <0;

--These are structurally fragile — deposits exceed core capital significantly
-- Negative core_capital_to_deposits_pct means core capital is insufficient to cover deposit obligations — a serious liquidity risk signal
-- Family Bank (-78.7%) and Gulf African Bank (-1.4%) are flagged

--vii. Which banks are Well Capitalised BUT have high NPL?
select
	cca.bank_name,
	cca.total_capital_to_rwa_pct,
	cnl.npl_ratio_dec24_pct,
	case
		when cca.total_capital_to_rwa_pct >= 14.5
		and cnl.npl_ratio_dec24_pct > 20 then 'Capital Strong — NPL Risk'
		when cca.total_capital_to_rwa_pct >= 14.5
		and cnl.npl_ratio_dec24_pct <= 20 then 'Capital Strong — NPL Acceptable'
		when cca.total_capital_to_rwa_pct < 14.5
		and cnl.npl_ratio_dec24_pct > 20 then 'Double Risk — Capital AND NPL'
		else 'Capital Weak — NPL Acceptable'
	end as risk_profile
from
	cbk_capital_adequacy cca
join cbk_npl_loans cnl ON
	cca.bank_name = cnl.bank_name
order by
	cnl.npl_ratio_dec24_pct desc;


--Section 6
/* Questions to answer:
1. Year on year change in gross loans per bank

2. Which banks grew their loan book the most?
   Which banks shrank?

3. Year on year change in NPL amount
   (gross_npl_dec24 - gross_npl_dec23)
   Growing loan book + growing NPL = double risk

4. Deposits to loans ratio per bank using cbk_market_share
   (total_deposits / loan_accounts_count)
   Which banks are most efficiently converting deposits to loans? */

--i.  Year on year change in gross loans per bank
select
	cnl.bank_name ,
	cnl.gross_loans_dec23_ksh_m ,
	cnl.gross_loans_dec24_ksh_m ,
	(cnl.gross_loans_dec24_ksh_m - cnl.gross_loans_dec23_ksh_m )* 100 / cnl.gross_loans_dec23_ksh_m  as change_in_gross_loans
from
	cbk_npl_loans cnl ;

--ii.Which banks grew their loan book the most? and Which banks shrank?
select
	cnl.bank_name ,
	cnl.gross_loans_dec23_ksh_m ,
	cnl.gross_loans_dec24_ksh_m ,
	(cnl.gross_loans_dec24_ksh_m - cnl.gross_loans_dec23_ksh_m )* 100 / cnl.gross_loans_dec23_ksh_m as change_in_gross_loans,
	case
		when cnl.gross_loans_dec23_ksh_m > cnl.gross_loans_dec24_ksh_m then 'Shrank'
		when cnl.gross_loans_dec23_ksh_m < cnl.gross_loans_dec24_ksh_m then 'Grew'
		else 'Stable'
	end as loan_book_status
from
		cbk_npl_loans cnl ;

--iii.  Year on year change in NPL amount

select
	cnl.bank_name ,
	cnl.gross_npl_dec23_ksh_m ,
	cnl.gross_npl_dec24_ksh_m  ,
	(cnl.gross_npl_dec24_ksh_m - cnl.gross_npl_dec23_ksh_m )* 100 / cnl.gross_npl_dec23_ksh_m  as change_in_gross_npl
from
	cbk_npl_loans cnl ;

--iv.-- Double risk flag: banks growing loan book AND growing NPL simultaneously   
	-- Growing loan book + growing NPL = double risk
select 
    cnl.bank_name,
    (cnl.gross_loans_dec24_ksh_m - cnl.gross_loans_dec23_ksh_m) * 100 / cnl.gross_loans_dec23_ksh_m as loan_growth_pct,
    (cnl.gross_npl_dec24_ksh_m - cnl.gross_npl_dec23_ksh_m) * 100 / cnl.gross_npl_dec23_ksh_m as npl_growth_pct,
    case when cnl.gross_loans_dec24_ksh_m > cnl.gross_loans_dec23_ksh_m
      and cnl.gross_npl_dec24_ksh_m   > cnl.gross_npl_dec23_ksh_m
       then 'Double Risk — Loan AND NPL Growth'
       when cnl.gross_loans_dec24_ksh_m > cnl.gross_loans_dec23_ksh_m
        then 'Loan Growth Only'
        when cnl.gross_npl_dec24_ksh_m   > cnl.gross_npl_dec23_ksh_m
        then 'NPL Growth Only'
        else 'No Growth Risk'
    end as risk_flag
from cbk_npl_loans cnl
order by 4;

--v. Deposits to loans ratio per bank using cbk_market_share
-- (total_deposits / loan_accounts_count)
--  Which banks are most efficiently converting deposits to loans?
select
	cms.bank_name,
	cms.total_deposits_ksh_m ,
	cms.loan_accounts_count,
		round(cms.total_deposits_ksh_m / cms.loan_accounts_count , 2) as ksh_per_loan_account
from
	cbk_market_share cms
order by
	4 desc;
-- 12 banks: Double Risk — loan AND NPL growth simultaneously
-- 6 banks: Loan Growth Only — credit expanding, asset quality holding
-- 14 banks: NPL Growth Only — shrinking books but NPLs still rising (most concerning)
-- 6 banks: No Growth Risk — both contracting, conservative/deleveraging posture
-- DIB Bank Kenya Ltd most extreme — NPL surged 150% on just 5% loan growth
-- UBA Kenya best performer — loans -56%, NPLs -86% (active cleanup)


--Section 7:Trend Analysis -loan growth yoy
with data as (
select
	bank_name,
	cnl.gross_loans_dec23_ksh_m gross_loans_2023,
	cnl.gross_loans_dec24_ksh_m gross_loans_2024,
	cnl.gross_npl_dec23_ksh_m as gross_npl_2023,
	cnl.gross_npl_dec24_ksh_m as gross_npl_2024
from
	cbk_npl_loans cnl),
yoy_gross_loans as (
select
	bank_name,
	gross_loans_2024,
		gross_loans_2023,
	gross_loans_2024 - gross_loans_2023 as gross_loans_diff,
	concat(round((gross_loans_2024 - gross_loans_2023) * 100 / gross_loans_2023, 2), '%') as growth_gross_loans_rate,
	case
		when gross_loans_2023 > gross_loans_2024 then 'gross loan reduced'
		when gross_loans_2023 < gross_loans_2024 then 'gross loan grew'
		else 'stable'
	end as gross_loan_status
from
	data
),
yoy_npl_loans as (
select
	bank_name,
	gross_npl_2024,
	gross_npl_2023,
	gross_npl_2024 - gross_npl_2023 as gross_npl_diff,
	concat(round((gross_npl_2024 - gross_npl_2023) * 100 / gross_npl_2023 , 2), '%') as growth_gross_npl_rate,
	case
		when gross_npl_2023 > gross_npl_2024 then 'gross npl reduced'
		when gross_npl_2023 < gross_npl_2024 then 'gross npl grew'
		else 'stable'
	end as gross_npl_status
from
	data)
select
	y1.bank_name,
	y1.gross_loans_2023,
	y1.gross_loans_2024,
	y1.gross_loans_diff,
	y1.growth_gross_loans_rate,
	y1.gross_loan_status,
	y2.gross_npl_2023,
	y2.gross_npl_2024,
	y2.gross_npl_diff,
	y2.growth_gross_npl_rate,
	y2.gross_npl_status,
	case
		when y1.gross_loans_diff < 0
		and y2.gross_npl_diff < 0 then 'Healthy Deleveraging'
		when y1.gross_loans_diff < 0
		and y2.gross_npl_diff > 0 then 'Distressed Contraction'
		when y1.gross_loans_diff > 0
		and y2.gross_npl_diff > y1.gross_loans_diff 
    then 'Risky Growth'
		when y1.gross_loans_diff > 0
		and y2.gross_npl_diff <= 0 
    then 'Healthy Growth'
		else 'Watch'
	end as lending_quality
from
	yoy_gross_loans y1
join yoy_npl_loans y2 on
	y1.bank_name = y2.bank_name
order by
	y1.gross_loans_diff desc;

-- Section 7: Loan Growth Trend Analysis YoY (Dec 2023 vs Dec 2024)
-- Flags banks expanding loans while NPL deteriorates (Risky Growth)
-- vs. banks shrinking loans while improving credit quality (Healthy Deleveraging)
-- Classification: Healthy Growth | Risky Growth | Healthy Deleveraging | Distressed Contraction | Watch


	--Section 8: Data Quality
	-- Banks in market_share not matched in profitability
	select
		bank_name,
		'Missing from profitability' AS issue
	from
		cbk_market_share
except
	select
		bank_name,
		'Missing from profitability'
	from
		cbk_profitability;
-- Result: 5 banks have name formatting inconsistencies between tables
-- e.g. 'KCB Bank Kenya Limited' vs 'KCB Bank Kenya Ltd'
-- These banks return NULL in Section 4 joins — a data quality limitation
--Section 8 :Executive Summary
-- See README.md for full findings and recommendations
