/* ================================================
   CBK Market Share Analysis - SQL Basics
   Author: Lucy Wangui
   Date: 16th March 2026
   Data Source: CBK Bank Supervision Report 2024
   Description: Exploratory queries on Kenya banking
   sector market share, peer groups, and asset distribution
   ================================================ */

DROP TABLE IF EXISTS cbk_market_share;
CREATE TABLE cbk_market_share (
    bank_name TEXT,
    peer_group TEXT,
    market_size_index REAL,
    market_rank INTEGER,
    total_assets_ksh_m REAL,
    asset_market_share_pct REAL,
    total_deposits_ksh_m REAL,
    shareholders_funds_ksh_m REAL,
    deposit_accounts_count INTEGER,
    loan_accounts_count INTEGER,
    year INTEGER
);
select * from cbk_market_share ;

/* WHERE */
select * from cbk_market_share cms where peer_group = 'Large' order by cms.market_rank desc; /* gives banks with a large peer group in a descending order */
select * from cbk_market_share cms where cms.market_rank BETWEEN 5 AND 10;
select * from cbk_market_share 	where bank_name LIKE "B%";
select * from cbk_market_share cms where cms.shareholders_funds_ksh_m >= 60000;

/*Count how many banks are in each peer_group and show the peer group name alongside the count.*/
SELECT peer_group, count (peer_group) from cbk_market_share cms group by peer_group;
/*Retrieve bank_name and total_assets_ksh_m but only show banks where total assets are greater than 500,000. Order results from largest to smallest.*/
select bank_name, total_assets_ksh_m from cbk_market_share cms  where total_assets_ksh_m >500000 ORDER BY total_assets_ksh_m desc;
/*Find the total assets for each peer_group — show the peer group name and the sum of total_assets_ksh_m for each group.*/
select peer_group, sum(total_assets_ksh_m) from cbk_market_share cms group by cms.peer_group ;

/*Show the peer_group and the average asset market share (asset_market_share_pct) for each peer group, but only show groups where the average is greater than 2. Round the average to 2 decimal places.*/
select peer_group, Round(AVG(asset_market_share_pct),2) AS Average from cbk_market_share cms GROUP BY peer_group HAVING AVG(asset_market_share_pct) > 2;
/*Show bank_name, total_assets_ksh_m and deposit_accounts_count for banks where:
Total assets are greater than 100,000 AND
Deposit accounts are greater than 1,000,000 */
select bank_name, total_assets_ksh_m, deposit_accounts_count FROM cbk_market_share cms  WHERE total_assets_ksh_m > 100000 AND deposit_accounts_count > 1000000;

/*Show bank_name and total_assets_ksh_m for banks whose total assets are above the average total assets of all banks in the table.*/
select bank_name, total_assets_ksh_m FROM cbk_market_share cms WHERE total_assets_ksh_m > (SELECT AVG(total_assets_ksh_m) FROM cbk_market_share cms) ;

/*For each peer_group, show:
peer_group
Number of banks (COUNT)
Total assets (SUM)
Average asset market share rounded to 2 decimal places (AVG)
The bank with the highest total assets in that group (MAX)
Order results by total assets descending.*/
select peer_group,count(bank_name), SUM(total_assets_ksh_m), Round(AVG(asset_market_share_pct),2)
,MAX(total_assets_ksh_m) FROM cbk_market_share cms GROUP BY peer_group ORDER BY total_assets_ksh_m DESC;