DROP TABLE IF EXISTS cbk_npl_loans;
CREATE TABLE cbk_npl_loans (
    bank_name TEXT,
gross_loans_dec23_ksh_m INTEGER,
gross_loans_dec24_ksh_m INTEGER,
gross_npl_dec23_ksh_m INTEGER,
gross_npl_dec24_ksh_m INTEGER,
npl_ratio_dec23_pct INTEGER,
npl_ratio_dec24_pct INTEGER );   

 select * from cbk_npl_loans cnl ;
 
 DROP TABLE IF EXISTS cbk_profitability;
 CREATE TABLE cbk_profitability ( bank_name TEXT,
profit_before_tax_ksh_m INTEGER,
total_assets_ksh_m INTEGER,
return_on_assets_pct INTEGER,
shareholders_funds_ksh_m INTEGER,
return_on_equity_pct INTEGER,
year INTEGER);

 select * from cbk_profitability cp;
 select * from cbk_market_share cms ;
 
 /*1. Join cbk_market_share and cbk_profitability to show each bank's peer_group, market_rank, and return_on_equity_pct. Order by market_rank.*/
select
	ms.bank_name,
	ms.peer_group,
	ms.market_rank,
	p.return_on_equity_pct
from
	cbk_market_share ms
join cbk_profitability p on
	ms.bank_name = p.bank_name
order by
	3 ;
/* bank_name inconsistencies exist across tables (e.g. 'Limited' vs 'Ltd')
 A production solution would use a unique bank_id as the join key instead of bank_name */
 
 
 /*2. show all banks in the market share table and their profit_before_tax_ksh_m. Show banks that have no profitability data — what does their profit column show? */
 select
	ms.bank_name,
	p.profit_before_tax_ksh_m,
	case
		when p.profit_before_tax_ksh_m is null then 'No profit data'
		else cast(p.profit_before_tax_ksh_m as varchar) 
	end as profit_status
from
	cbk_market_share ms left join cbk_profitability p on ms.bank_name = p.bank_name;
 
 --5 banks return NULL for profit_before_tax_ksh_m
-- This is due to bank_name inconsistencies across tables, not missing data
-- And a unique bank_id join key would resolve this in production
 
--checking the banks with profitability data and no bank name and those with bank name and no profitability data
  select
	ms.bank_name,
	p.profit_before_tax_ksh_m,
	case
		when p.profit_before_tax_ksh_m is null then 'No profit data'
		else cast(p.profit_before_tax_ksh_m as varchar) 
	end as profit_status
from
	cbk_market_share ms full join cbk_profitability p on ms.bank_name = p.bank_name;
 
 
 
 /*3. Join all three tables to return each bank's peer_group, npl_ratio_dec24_pct, and return_on_assets_pct. Only include banks that appear in all three tables.*/
select
	ms.bank_name,
	ms.peer_group,
	npl.npl_ratio_dec24_pct,
	p.return_on_assets_pct
from
	cbk_market_share ms
join cbk_npl_loans npl on
	ms.bank_name = npl.bank_name
join cbk_profitability p on
	ms.bank_name = p.bank_name; 
 
-- JOIN across all three tables returns only banks with matching names in all three
-- Row count of 7 banks is lower than expected due to bank_name inconsistencies across datasets
-- e.g. 'KCB Bank Kenya Limited' vs 'KCB Bank Kenya Ltd' vs 'KCB Bank Kenya Plc'
 
 
 
 /*4. For each peer_group calculate:
Average NPL ratio (Dec 2024)
Count of banks where NPL ratio worsened from 2023 to 2024
Count of banks where NPL ratio improved */
 
 select
	ms.peer_group,
	AVG(npl.npl_ratio_dec24_pct) as average_npl_ratio,
	count(case when npl_ratio_dec24_pct < npl_ratio_dec23_pct then 1 else null end) as banks_npl_worsened,
	count(case when npl_ratio_dec24_pct = npl_ratio_dec23_pct then 1 else null end) as banks_npl_unchanged,
	count(case when npl_ratio_dec24_pct > npl_ratio_dec23_pct then 1 else null end) as banks_npl_improved
from
	cbk_market_share ms
join cbk_npl_loans npl on
	ms.bank_name = npl.bank_name
	group by 1;
 
 
 
 /*5. Show only banks where return_on_equity_pct is positive but npl_ratio_dec24_pct is above 20%.Return bank_name, return_on_equity_pct, and npl_ratio_dec24_pct.*/
 
 select
	ms.bank_name,
	p.return_on_equity_pct,
	npl.npl_ratio_dec24_pct
from
	cbk_market_share ms
join cbk_profitability p on
	ms.bank_name = p.bank_name
join cbk_npl_loans npl on
	ms.bank_name = npl.bank_name
where
	p.return_on_equity_pct > 0
	and
	npl.npl_ratio_dec24_pct > 20
order by
	npl_ratio_dec24_pct desc
;
 
-- Result: National Bank of Kenya is the only bank generating positive returns
-- despite an NPL ratio above 20% (NPL: 33.2%, ROE: 7.1%)
-- This warrants further investigation into their provisioning strategy
 

/*6. The finance team wants a single list of all unique bank names across cbk_profitability and cbk_npl. Some banks appear in both, 
 some in only one. Return a deduplicated list and a column called source showing where each bank came from:
'Both' if in both tables
'Profitability Only' if only in profitability
'NPL Only' if only in NPL */
select
	distinct p.bank_name,
	'Both' as source
from
	cbk_profitability p
join cbk_npl_loans npl on
	p.bank_name = npl.bank_name
union all
select
	distinct p.bank_name,
	'Profitability Only' as source
from
	cbk_profitability p
left join cbk_npl_loans npl on
	p.bank_name = npl.bank_name
where
	npl.bank_name is null
union 
select
	distinct npl.bank_name,
	'NPL Only' as source
from
	cbk_profitability p
right join cbk_npl_loans npl on
	p.bank_name = npl.bank_name
where
	p.bank_name is null 
;

-- Results intentionally left unordered to highlight the impact of bank_name
-- inconsistencies across tables. Banks with slight name variations
-- (e.g. 'Guaranty Trust Bank(K) Ltd' vs 'Guaranty Trust Bank Ltd') appear in
-- 'Profitability Only' and 'NPL Only' instead of 'Both', despite being the same bank.
-- This demonstrates why a unique bank_id is critical in production database design.
 
 /*7. Combine total_assets_ksh_m from both cbk_market_share and cbk_profitability into one dataset with a column called source_table.
   Then show the average total assets per source table. Do the two tables agree on asset values? */

select
	cast(avg(total_assets)as integer) as avg_total_assets,
	source_table
from
	(
	select
		total_assets_ksh_m as total_assets,
		'cbk_market_share' as source_table
	from
		cbk_market_share
union all
	select
		total_assets_ksh_m as total_assets,
		'cbk_profitability' as source_table
	from
		cbk_profitability
) as combined
group by 2;

-- cbk_market_share avg total assets: KSh 405,115M (17 banks — Large and Medium only)
-- cbk_profitability avg total assets: KSh 194,050M (39 banks — all peer groups)
-- Difference of KSh 211,065M explained by coverage scope, not a data error
-- Small banks in cbk_profitability pull the average down significantly

