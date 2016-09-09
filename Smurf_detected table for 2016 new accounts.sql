CREATE table bi_sandbox.mjang_new2016_smurfdetected
(account_id INT,
Smurf Boolean);

copy   bi_sandbox.mjang_new2016_smurfdetected  from local 
'C:\Users\mjang\Desktop\Business analytics\projects\2016\스머프 분석 - 알고리즘 업데이트\newaccounts2016_smurf detected1.csv' delimiter E',' enclosed by '"';

select count(*) from bi_sandbox.mjang_new2016_smurfdetected
                        

SELECT C.Smurf, avg(levels), avg(games), avg(bots), avg(wins), avg(wins/games), avg(bots/games), count(*)
FROM
(select 
A.account_id, Smurf, count(game_id) as games, max(level) as levels
, sum(case when elo_change = 0 then 1 end) as bots
,sum(case when elo_change > 0 then 1 end) as wins
FROM
bi_sandbox.mjang_new2016_smurfdetected A
LEFT OUTER JOIN
realm_4.audit_player_game_statistics B
on A.account_id= B.account_id group by a.account_id, Smurf) as C
GROUP BY Smurf

select account_type, count(*) from bi_reports.monthly_unique_players where realm_id = 4 and current_month_start_date between '2016-01-01' and '2016-06-01' 
group by account_type


//churn trend
select smurf, account_type, current_month_start_date, count(*) from 
bi_sandbox.mjang_new2016_smurfdetected A
LEFT OUTER JOIN
bi_reports.monthly_unique_players B 
on A.account_id = B.account_id
 where realm_id = 4
 group by smurf, account_type, current_month_start_date


//churn by level

select max_level_current_month, smurf, count(*) as active
, count(distinct(case when  account_type in ('Churned', 'New Account Churned') then A.account_id end)) as churned_all
, count(distinct(case when  account_type = 'New Account Churned' then A.account_id end)) as churned FROM
bi_sandbox.mjang_new2016_smurfdetected A
LEFT OUTER JOIN
bi_reports.monthly_unique_players B 
on A.account_id = B.account_id
 where realm_id = 4 
 group by max_level_current_month, smurf, current_month_start_date


select  max_level_current_month, account_type, current_month_start_date, count(*) 
 FROM
bi_reports.monthly_unique_players 
 where realm_id = 4 and current_month_start_date > '2016-01-01' group by max_level_current_month, account_type, current_month_start_date


 
 
//30레벨 도달 계정수
select smurf, RD, count(distinct(A.account_id)), count(distinct(case when max_level_current_month = 30 then A.account_id else 0 end)) as lv30
FROM
        (SELECT A1.account_id, smurf, date(date_trunc( 'month', create_datetime)) as RD FROM
        bi_sandbox.mjang_new2016_smurfdetected as A1
        left outer join 
        staging.platform_accounts as A2 on A1.account_id = A2.account_id 
        where A2.realm_id =4
        group by A1.account_id, RD, smurf) A
LEFT OUTER JOIN
bi_reports.monthly_unique_players B 
on A.account_id = B.account_id
where realm_id = 4 
group by smurf, RD


//가입 월별 30레벨 다는데 걸리는 평균 기간, 도달 비율

select date(date_trunc('month', RD)) as MM, avg((TIMESTAMPDIFF(MINUTE, RD, lv30))/3600)
, count(distinct(A.account_id)) all_acount, count(distinct(case when lv30 is not null then A.account_id else 0 end)) as lv30_account from
(select account_id, date(create_datetime) as RD
FROM staging.platform_accounts 
where realm_id =4 group by account_id, RD) A
LEFT OUTER JOIN
(select B1.account_id, lv30 FROM
(select account_id,  min(date(create_datetime)) as lv30 FROM
realm_4.audit_player_game_statistics where level = 30 group by account_id) B1
LEFT OUTER JOIN
(select account_id, min(level) min_level from realm_4.audit_player_game_statistics group by account_id) B2
on B1.account_id = B2.account_id where min_level < 30
) B
on A.account_id = B.account_id group by MM


//9월에 가입한 플레이어들 중 만렙
select * FROM
(select A.account_id, RD, TIMESTAMPDIFF(MINUTE, RD, lv30)/3600 FROM
(select account_id, date(create_datetime) as RD
FROM staging.platform_accounts 
where realm_id =4 group by account_id, RD) A
LEFT OUTER JOIN
(select B1.account_id, lv30 FROM
(select account_id,  min(date(create_datetime)) as lv30 FROM
realm_4.audit_player_game_statistics where level = 30 group by account_id) B1
LEFT OUTER JOIN
(select account_id, min(level) min_level from realm_4.audit_player_game_statistics group by account_id) B2
on B1.account_id = B2.account_id where min_level < 30
) B
on A.account_id = B.account_id where RD>='2016-09-01' and lv30 is not null) C LEFT OUTER JOIN realm_4.audit_player_game_statistics D 
on C.account_id = D.account_id


///moneization differencia entre smurf y novato.

select select smurf, transaction_type,  count(*) from 
bi_sandbox.mjang_new2016_smurfdetected SM
LEFT OUTER JOIN
(SELECT SA.account_id, ST.* FROM
(select store_account_id, transaction_type, B.item_id, ip_delta, rp_delta, inventory_type 
from realm_4.store_transactions A LEFT OUTER JOIN realm_4.store_items B
on A.item_id = B.item_id) ST
LEFT OUTER JOIN realm_4.store_accounts SA
on ST.store_account_id = SA.store_account_id) TD






