//테이블 생성
drop table bi_sandbox.mjang_jp_native_flag
 
Create table bi_sandbox.mjang_jp_native_flag as
        (select c.ACCOUNT_ID, (case when c.native_jp = 1 and D.ping <60 then 1 else 0 end) as native_jp, ping
        FROM
                (select A.account_id, (CASE WHEN  A.CD < '2016-01-01' or B.realm_name='jp' or realm_name is null then 1 else 0 end) as native_jp
                FROM            
                (SELECT AY.account_id, AY.user_name, min(AZ.create_datetime) as CD FROM
                (Select saa.account_id, saa.user_name FROM
                (select account_id, user_name, max(date(modify_datetime)) as max_date, date(modify_datetime) as normal_date
                from  staging.platform_accounts where realm_id = 62 group by account_id, user_name, normal_date) saa where saa.max_date = saa.normal_date
                group by account_id, user_name) AY
                LEFT OUTER JOIN
                staging.platform_accounts AZ
                on AY.account_id = AZ.account_id group by AY.account_id, AY.user_name) A                              
                left outer join
                (select pvpnet_account_name, realm_name from staging.signup_pvpnet_accounts group by pvpnet_account_name, realm_name) B
                on A.user_name = B.pvpnet_account_name
               group by a.account_id, A.CD, B.realm_name order by native_jp) C
        left outer join 
                (SELECT 
                account_id, avg(user_server_ping) as ping
                from staging.audit_player_game_statistics where realm_id = 62 group by account_id) D
        on c.account_id = d.account_id) 
//확인
select count(distinct(account_id)), native_jp from  bi_sandbox.mjang_jp_native_flag group by native_jp

select * from  bi_sandbox.mjang_jp_native_flag limit 10000

//monthly 업로드 확인 
select * from bi_reports.monthly_unique_players where realm_id = 62 order by current_month_start_date desc limit 100

//monthly active확인
select current_month_start_date, count(distinct(A.account_id)), native_jp FROM bi_reports.monthly_unique_players A left outer join bi_sandbox.mjang_jp_native_flag B
on A.account_id = B.account_id where A.realm_id = 62 and active_current_month = 'TRUE' group by current_month_start_date, native_jp

select current_month_start_date, count(account_id)
FROM bi_reports.monthly_unique_players  where realm_id = 62 and active_current_month = 'TRUE'  group by current_month_start_date

//월별 추이 with flag
SELECT account_type, native_jp, current_month_start_date, count(distinct(report.account_id))
FROM
(SELECT * from bi_reports.monthly_unique_players where realm_id = 62) report
left outer join
bi_sandbox.mjang_jp_native_flag BASE
on report.account_id = base.account_id
group by  account_type, native_jp, current_month_start_date

//월별 추이 without flag
SELECT account_type, current_month_start_date, count(distinct(account_id))
 from bi_reports.monthly_unique_players where realm_id = 62
group by  account_type, current_month_start_date

//월별 지표 추이
select count(*), current_month_start_date, sum(case when usd_spent is not null then 1 else 0 end) as mo, Base.native_jp,
avg(usd_spent)as arppa, sum(usd_spent) as usd, avg(hours_played) as hours, sum(hours_played) as hoursum, sum(case when hours_played is not null then 1 else 0 end) as active
FROM
(select * from bi_reports.monthly_unique_players where realm_id = 62) A
left outer join 
bi_sandbox.mjang_jp_native_flag BASE
on A.account_id = Base.account_id 
 group by current_month_start_date, Base.native_jp


//flag 별 월별 평균
select current_month_start_date, native_jp,
usd/active as arpa, play/active as aghpa, mo/active, usd as total_spent, mo*arppa
from
(select current_month_start_date, native_jp,
sum(usd_spent) as usd, sum(hours_played) as play, count(distinct(case when active_current_month= 'TRUE' then A.account_id else 0 end)) as active,
count(distinct(case when usd_spent is not null then A.account_id else 0 end)) as mo, avg(usd_spent) as arppa
FROM
(select * from bi_reports.monthly_unique_players where realm_id = 62) A
left outer join 
(select account_id, native_jp from bi_sandbox.mjang_jp_native_flag group by account_id, native_jp) BASE
on A.account_id = Base.account_id group by current_month_start_date, Base.native_jp) D

//월별 평균 sin flag
select current_month_start_date,
usd/active as arpa, play/active as aghpa, mo/active, usd as total_spent, arppa*mo
from
(select current_month_start_date, sum(usd_spent) as usd, sum(hours_played) as play
, count(distinct(case when active_current_month= 'TRUE' then account_id else 0 end)) as active,
count(distinct(case when usd_spent is not null then account_id else 0 end)) as mo, avg(usd_spent) as arppa from bi_reports.monthly_unique_players where realm_id = 62
group by  current_month_start_date) d



select current_month_start_date, sum(usd_spent) from bi_reports.monthly_unique_players where realm_id = 62
group by current_month_start_date
