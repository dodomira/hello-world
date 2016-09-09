//DAU
SELECT 
DD, native_jp, count(distinct(dau.account_id))
FROM
(select account_id, date(create_datetime + interval '17 hours' ) as DD 
FROM staging.audit_player_game_statistics where realm_id = 62 group by account_id, DD) DAU
LEFT OUTER JOIN
        (select c.ACCOUNT_ID, (case when c.native_jp = 1 and D.ping <60 then 1 else 0 end) as native_jp, ping
        FROM
                (select A.account_id, sum(CASE WHEN A.CD < '2016-01-01' or B.realm_name='jp' or realm_name is null then 1 
                else 0 end) as native_jp
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
               group by a.account_id order by native_jp) C
        left outer join 
                (SELECT 
                account_id, avg(user_server_ping) as ping
                from staging.audit_player_game_statistics where realm_id = 62 group by account_id) D
        on c.account_id = d.account_id) BASE
on DAU.account_id= BASE.account_id group by dd, native_jp

//Playhours
select game_date,  native_jp, sum(game_length) as game_total, count(distinct(gh.account_id)) as DAU,  avg(game_length) as game_avg from 
        (SELECT account_id, date(date_trunc('day', PG.create_datetime+interval '17hours')) game_date,  sum(TIMESTAMPDIFF(MINUTE,GH.create_datetime,PG.create_datetime))/60 as game_length
        FROM 
                (select game_id, create_datetime, realm_id, account_id from staging.audit_player_game_statistics where realm_id=62) PG 
        INNER JOIN (
                select game_id, create_datetime
                from staging.audit_game_config_history
                where realm_id=62 and create_datetime > '2016-02-29 00:00:00' 
                ) GH ON PG.game_id=GH.game_id
        WHERE PG.realm_id = 62 AND PG.create_datetime > '2016-02-29 00:00:00' 
        GROUP BY game_date, account_id order by game_date ) GH
left outer join 
            (select c.ACCOUNT_ID, (case when c.native_jp = 1 and D.ping <60 then 1 else 0 end) as native_jp, ping
        FROM
                (select A.account_id, sum(CASE WHEN A.CD < '2016-01-01' or B.realm_name='jp' or realm_name is null then 1 
                else 0 end) as native_jp
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
               group by a.account_id order by native_jp) C
        left outer join 
                (SELECT 
                account_id, avg(user_server_ping) as ping
                from staging.audit_player_game_statistics where realm_id = 62 group by account_id) D
        on c.account_id = d.account_id)  BASE
on base.account_id = gh.account_id group by game_date,  native_jp

//counter check
select date(create_datetime+interval '17 hours') DD, avg(ccu) ACU, max(ccu) PCU from staging.cacti_ccu_stats
where realm_id_cacti = '62'
and create_datetime >= '2016-01-01'
group by DD
order by DD



//new registration
SELECT DD, native_jp, count(distinct(NR.account_id)) FROM
(select date(create_datetime + interval '17 hours') DD, account_id  from staging.platform_accounts
where create_datetime >= '2016-03-01' and realm_id=62
group by DD, account_id) NR
LEFT OUTER JOIN
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
        on c.account_id = d.account_id) BASE
ON NR.account_id = BASE.account_id group by DD, native_jp


//paying accounts & revenue
select tr.dd, native_jp, count(distinct(tr.store_account_id)) as paying, sum(b2c) as total_rp, avg(b2c) as average_rp
FROM
(select date(transaction_datetime + interval '17 hours') DD, store_account_id,  sum(rp_delta) as b2c from staging.store_transactions
where transaction_type = 'USER_PURCHASED_RP' and rp_delta > 0 and transaction_datetime >= '2016-03-01' and realm_id = 62
group by DD, store_Account_id) tr
left outer join
(SELECT BASE.account_id, native_jp, store_account_id
FROM
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
        on c.account_id = d.account_id group by native_jp, c.account_id, ping) BASE 
LEFT outer join
(select store_account_id, account_id from staging.store_Accounts where realm_id = 62) as store
on base.account_id = store.account_id) SB
on tr.store_Account_id = sb.store_account_id group by dd, native_jp


//Playhours
SELECT date(date_trunc('day', PG.create_datetime+interval '17hours')) game_date,  sum(TIMESTAMPDIFF(MINUTE,GH.create_datetime,PG.create_datetime))/60 "Game Length"
FROM 
        (select game_id, create_datetime, realm_id from staging.audit_player_game_statistics where realm_id=62) PG 
INNER JOIN (
        select game_id, create_datetime
        from staging.audit_game_config_history
        where realm_id=62 and create_datetime > '2016-02-29 00:00:00' 
        ) GH ON PG.game_id=GH.game_id
WHERE PG.realm_id = 62 AND PG.create_datetime > '2016-02-29 00:00:00' 
GROUP BY game_date order by game_date asc


//ACU & PCU
select date(create_datetime+interval '17hours') DD, avg(ccu) ACU, max(ccu) PCU from staging.cacti_ccu_stats
where realm_id_cacti = '62'
and create_datetime >= '2016-03-01'
group by DD
order by DD


//Unique Login
select date(create_datetime+interval '17hours') DD, count(distinct(user_name)) UniqueLogin from staging.audit_user_session_history
where action = 'LOGIN'
and create_datetime >= '2016-03-01'
and realm_id=62
group by DD
order by DD


//DAU üũ
select date(create_datetime+interval '17hours') DD, count(distinct(account_id)) from staging.audit_player_game_statistics
where create_datetime >= '2016-03-01'
and realm_id = 62
group by DD
order by DD


