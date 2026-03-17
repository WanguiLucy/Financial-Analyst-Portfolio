
/* CASE WHEN + AGGREGATE */

/*"Classify each bank as 'Dominant', 'Strong', 'Moderate', or 'Minor' player based on their asset_market_share_pct, then count how many banks fall into each category."*/

-- Dominant: 13%+  |  Strong: 7–12.9%  |  Moderate: 4–6.9%  |  Minor: <4%
select
	CASE
		WHEN asset_market_share_pct >= 13 THEN 'Dominant'
		WHEN asset_market_share_pct >= 7 THEN 'Strong'
		WHEN asset_market_share_pct >=4 THEN 'Moderate'
		ELSE 'Minor'
	END AS market_share,
	COUNT(1) AS Number_of_banks
from
	cbk_market_share cms
GROUP BY
	1;

/*"For each peer_group, calculate the total deposits, average market size index, and the number of banks. Order by total deposits descending."*/
SELECT
	 peer_group,
	SUM(cms.total_deposits_ksh_m) AS total_deposits,
	AVG(cms.market_size_index) AS average_market_size,
	COUNT(bank_name) AS number_of_banks
from
	cbk_market_share cms
GROUP BY
	peer_group
ORDER BY
	SUM(cms.total_deposits_ksh_m) DESC;

/*"How many banks have a loan_accounts_count that is higher than their deposit_accounts_count? Return just that single number."*/
select
	COUNT(CASE WHEN loan_accounts_count > deposit_accounts_count THEN loan_accounts_count ELSE NULL END) AS higher_loan_accounts
from
	cbk_market_share cms ;

/*1. Classify each bank into a performance tier based on asset_market_share_pct:

"Dominant" if share > 10%
"Strong" if between 5% and 10% (inclusive)
"Moderate" if between 2% and 5%
"Small Player" otherwise

Return: bank_name, asset_market_share_pct, and performance_tier. Order by share descending. */

select
	bank_name,
	asset_market_share_pct,
	case
		when asset_market_share_pct > 10 then 'Dominant'
		when asset_market_share_pct >= 5
		and cms.asset_market_share_pct <= 10 then 'Strong'
		when asset_market_share_pct > 2 then 'Moderate'
		Else 'Small Player'
	end AS performance_tier
from
	cbk_market_share cms
order by
	asset_market_share_pct desc ;


/*2. For each peer_group, calculate:

Total combined assets
Average deposit accounts
The bank with the highest market_size_index (hint: use MAX)

Return the peer group, all three metrics. */

select
	peer_group,
	SUM(cms.total_assets_ksh_m) AS combined_assets,
	AVG(cms.deposit_accounts_count) AS average_deposit_accounts,
	MAX(cms.market_size_index) AS large_market_size
from
	cbk_market_share cms
group by
	peer_group ; 

/*3. Find peer groups where the average asset_market_share_pct is greater than 3%.
Return: peer_group and avg_share. Only show groups that pass the threshold. */

select
	peer_group,
	AVG(cms.asset_market_share_pct) AS average_market_share
from
	cbk_market_share cms
group by
	peer_group
having
	AVG(asset_market_share_pct) > 3 ;

/*4. How many unique peer groups exist in the dataset?
Then write a second query: list the distinct peer groups alongside how many banks fall in each. */

select
	count(distinct peer_group) AS number_of_peer_group
from
	cbk_market_share cms ;

select
	peer_group,
	count(bank_name) AS number_of_banks
from
	cbk_market_share cms
group by
	peer_group; 


/*5. Calculate, for the entire dataset:

The total assets of Large banks only 
The total assets of Medium banks only
The combined total of all banks

Return all three in a single row with clear column aliases. */

select
	sum(case when peer_group = 'Large' THEN total_assets_ksh_m ELSE NULL END) AS total_large_banks,
	sum(case when peer_group = 'Medium' THEN total_assets_ksh_m ELSE NULL END) AS total_medium_banks,
	sum(total_assets_ksh_m) as combined_assets
from
	cbk_market_share cms ;
	
/*6. List peer groups that have more than 5 banks AND where the minimum shareholders' funds is above KSh 10,000M.
Return: peer_group, bank_count, min_shareholders_funds.*/

select
	peer_group,
	count(bank_name) as bank_count,
	MIN(cms.shareholders_funds_ksh_m) as min_shareholders_funds
from
	cbk_market_share cms
group by
	peer_group
having
	count(bank_name)>5
	and MIN(cms.shareholders_funds_ksh_m) > 10000;

/*7. Write a query that returns each bank's name, peer group, and a column called account_dominance defined as:

"Deposit Heavy" if deposit_accounts_count > loan_accounts_count * 10
"Balanced" if deposit_accounts_count is between 2x and 10x loan_accounts_count
"Loan Heavy" if deposit_accounts_count < loan_accounts_count * 2

Then group by peer_group and account_dominance, and only show combinations that appear more than once. */

/*7a. query that returns each bank's name, peer group, and a column called account_dominance */
select
	bank_name,
	peer_group,
	case
		when deposit_accounts_count > loan_accounts_count * 10 then 'Deposit Heavy'
		when deposit_accounts_count > loan_accounts_count * 2
		and deposit_accounts_count <= loan_accounts_count * 10 then 'Balanced'
		else 'Loan Heavy'
	end as account_dominance
from
	cbk_market_share
ORDER BY
	peer_group,
	account_dominance
;


/*7b. show combinations that appear more than once */
SELECT
	peer_group,
	account_dominance,
	COUNT(*) AS bank_count
FROM
	(
	SELECT
		peer_group,
		CASE
			WHEN deposit_accounts_count > loan_accounts_count * 10 THEN 'Deposit Heavy'
			WHEN deposit_accounts_count > loan_accounts_count * 2
			AND deposit_accounts_count <= loan_accounts_count * 10 THEN 'Balanced'
			ELSE 'Loan Heavy'
		END AS account_dominance
	FROM
		cbk_market_share
) AS classified
GROUP BY
	peer_group,
	account_dominance
HAVING
	COUNT(*) > 1;