-- =============================================================
-- DO'reS「お知らせ」権限(RLS) 確認 — dores-dev の SQL Editor に貼って1回 Run
--   ・1回の実行で全部の合否を1行にまとめて返す
--   ・データは一切変更しない（書き込みテストは内部で自動的に巻き戻す）
--   ・service_role ではなく authenticated ロールを擬似再現（パスワード不要）
-- =============================================================

create function pg_temp.c(p_role text, p_sub uuid, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  if p_role = 'anon' then
    perform set_config('role','anon',true); perform set_config('request.jwt.claims','',true);
  else
    perform set_config('role','authenticated',true);
    perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  end if;
  execute p_sql into n; perform set_config('role','none',true); return n;
end $f$;

create function pg_temp.w(p_sub uuid, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  begin
    execute p_sql; get diagnostics n = row_count; raise exception 'TESTROLLBACK';
  exception
    when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then n := -1; end if;
    when others then n := -1;
  end;
  perform set_config('role','none',true); return n;
end $f$;

-- 関数を呼べるか（呼べたら0 / 権限エラーなら-1）
create function pg_temp.tc(p_role text, p_sub uuid, p_sql text) returns int language plpgsql as $f$
begin
  if p_role = 'anon' then
    perform set_config('role','anon',true); perform set_config('request.jwt.claims','',true);
  else
    perform set_config('role','authenticated',true);
    perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  end if;
  begin
    execute p_sql; perform set_config('role','none',true); return 0;
  exception when others then
    perform set_config('role','none',true); return -1;
  end;
end $f$;

-- acked_at が「クライアント指定値(2000年)を無視してnow()になる」か（なってたら1 / 2000のまま0）。必ず巻き戻す。
create function pg_temp.ack_now(p_sub uuid, p_notice uuid) returns int language plpgsql as $f$
declare got timestamptz; res int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  begin
    insert into notice_acks(notice_id, person_id, acked_at)
      values (p_notice, p_sub, timestamptz '2000-01-01 00:00:00') returning acked_at into got;
    res := case when got > now() - interval '1 minute' then 1 else 0 end;
    raise exception 'TESTROLLBACK';
  exception
    when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then res := -1; end if;
    when others then res := -1;
  end;
  perform set_config('role','none',true); return res;
end $f$;

with r(番号, テスト, 期待, 実際) as (values
  (1 ,'① anon お知らせ0件',0, pg_temp.c('anon',null,$q$select count(*) from notices$q$)),
  (2 ,'① anon 確認0件',0, pg_temp.c('anon',null,$q$select count(*) from notice_acks$q$)),
  (3 ,'② MAS お知らせ全9件(下書き含む)',9, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from notices$q$)),
  (4 ,'③ 店長A 見える3件',3, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from notices$q$)),
  (5 ,'③ 店長A 店舗B限定は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000009'$q$)),
  (6 ,'③ 店長A ランク限定は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000002'$q$)),
  (7 ,'③ 店長A 下書きは見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000005'$q$)),
  (8 ,'③ 店長A 終了は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000006'$q$)),
  (9 ,'① エリア階層: 店長A 関東(親)が見える',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000007'$q$)),
  (10,'① エリア階層: 店長A 西(他エリア)は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000008'$q$)),
  (11,'② 社員 見える5件',5, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000005',$q$select count(*) from notices$q$)),
  (12,'② 社員 ランク限定が見える',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000005',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000002'$q$)),
  (13,'③ アルバイト1 見える3件',3, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000006',$q$select count(*) from notices$q$)),
  (14,'③ アルバイト1 個人宛(他人)は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000006',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000004'$q$)),
  (15,'④ 店長A お知らせ作成=拒否(-1)',-1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000003',$q$insert into notices(title,body) values('不正','x')$q$)),
  (16,'④ 店長A お知らせ編集=拒否(0行)',0, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000003',$q$update notices set title=title where id='77777777-0000-0000-0000-000000000001'$q$)),
  (17,'⑤ 社員 自分の確認を記録=許可(1)',1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000005',$q$insert into notice_acks(notice_id,person_id) values('77777777-0000-0000-0000-000000000002','aaaaaaaa-0000-0000-0000-000000000005')$q$)),
  (18,'⑤ 社員 他人の確認は不可(-1)',-1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000005',$q$insert into notice_acks(notice_id,person_id) values('77777777-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000003')$q$)),
  (19,'⑤ 社員 見えないお知らせは確認不可(-1)',-1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000005',$q$insert into notice_acks(notice_id,person_id) values('77777777-0000-0000-0000-000000000005','aaaaaaaa-0000-0000-0000-000000000005')$q$)),
  (20,'⑥ 店長A 確認状況=自店3件見える',3, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from notice_acks$q$)),
  (21,'⑥ 社員 確認状況=自分2件のみ',2, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000005',$q$select count(*) from notice_acks$q$)),
  (22,'⑦ anon 設定0件',0, pg_temp.c('anon',null,$q$select count(*) from app_settings$q$)),
  (23,'⑦ 店長A 設定が読める(1件)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from app_settings$q$)),
  (24,'② 設定の2行目は作れない(-1)',-1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000001',$q$insert into app_settings(id,company_display_name) values(2,'x')$q$)),
  (25,'③ MASでもお知らせ削除不可(0行)',0, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000001',$q$delete from notices where id='77777777-0000-0000-0000-000000000001'$q$)),
  (26,'⑦ MAS 設定更新=許可(1行)',1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000001',$q$update app_settings set company_display_name=company_display_name where id=1$q$)),
  (27,'⑦ 店長A 設定更新=拒否(0行)',0, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000003',$q$update app_settings set company_display_name=company_display_name where id=1$q$)),
  (28,'④ anon は notice_is_target を呼べない(-1)',-1, pg_temp.tc('anon',null,$q$select notice_is_target('77777777-0000-0000-0000-000000000001')$q$)),
  (29,'④ anon は my_area_ids を呼べない(-1)',-1, pg_temp.tc('anon',null,$q$select count(*) from my_area_ids()$q$)),
  (30,'④ anon は current_rank_id を呼べない(-1)',-1, pg_temp.tc('anon',null,$q$select current_rank_id()$q$)),
  (31,'④ 店長A は notice_is_target を呼べる(0)',0, pg_temp.tc('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select notice_is_target('77777777-0000-0000-0000-000000000001')$q$)),
  (32,'② acked_at は指定しても必ずnow()(1)',1, pg_temp.ack_now('aaaaaaaa-0000-0000-0000-000000000005','77777777-0000-0000-0000-000000000002'))
)
select
  (select count(*) from r)                   as 件数,
  (select count(*) from r where 期待 = 実際)  as pass,
  (select count(*) from r where 期待 <> 実際) as fail,
  case when (select count(*) from r where 期待 <> 実際) = 0
       then '✅ 全部OK（合格）'
       else '⚠ 不合格: ' || (select string_agg('['||番号||'] '||テスト||'(期待'||期待||'/実際'||実際||')', ' / ') from r where 期待 <> 実際)
  end                                        as 結果;
