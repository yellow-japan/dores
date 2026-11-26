-- =============================================================
-- DO'reS「会社ごとに分ける(テナント)」分離 確認 — dores-dev の SQL Editor に貼って1回 Run
--   ・1回の実行で全部の合否を1行にまとめて返す
--   ・データは一切変更しない（書き込みテストは内部で自動的に巻き戻す）
--   ・service_role ではなく authenticated/anon ロールを擬似再現（パスワード不要）
--   前提: seed.sql（yellow）・seed_notices.sql・seed_tenant_b.sql（テスト株式会社B）を投入済み
--
--   登場人物:
--     A(yellow) MAS      = aaaaaaaa-0000-0000-0000-000000000001
--     A(yellow) アルバイト1 = aaaaaaaa-0000-0000-0000-000000000006
--     B(テスト株式会社B) MAS   = 0000bbbb-0000-0000-0000-000000000001
--     B アルバイト              = 0000bbbb-0000-0000-0000-000000000003
--   目印:
--     Aの全社お知らせ  = 77777777-0000-0000-0000-000000000001
--     Aの店舗A        = 55555555-0000-0000-0000-000000000001
--     Aの社員         = aaaaaaaa-0000-0000-0000-000000000005
--     Bの全社お知らせ  = 0000bbbb-0000-0000-0000-000000000071
--     Bの店舗1        = 0000bbbb-0000-0000-0000-000000000051
--     Bの店長         = 0000bbbb-0000-0000-0000-000000000002
--     yellowテナント   = 0000ffff-0000-0000-0000-000000000001
--     Bテナント        = 0000ffff-0000-0000-0000-000000000002
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

-- 書き込みテスト（必ず巻き戻す）。許可で変更行数、拒否で -1。
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

with r(番号, テスト, 期待, 実際) as (values
  -- A(yellow) は自分の会社だけ見える（件数は tenantB を足す前と同じ）
  (1 ,'A-MAS 店舗4件(自社のみ)',4, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from stores$q$)),
  (2 ,'A-MAS 人8件(自社のみ)',8, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from people$q$)),
  (3 ,'A-MAS 法人2件(自社のみ)',2, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from companies$q$)),
  (4 ,'A-MAS お知らせ9件(自社のみ)',9, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from notices$q$)),
  (5 ,'A-MAS 個人情報8件(自社のみ)',8, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from people_private$q$)),
  -- A-MAS は B のデータを ID 直指定しても見えない
  (6 ,'A-MAS Bの店舗は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from stores where id='0000bbbb-0000-0000-0000-000000000051'$q$)),
  (7 ,'A-MAS Bの人は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from people where id='0000bbbb-0000-0000-0000-000000000002'$q$)),
  (8 ,'A-MAS Bのお知らせは見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from notices where id='0000bbbb-0000-0000-0000-000000000071'$q$)),
  (9 ,'A-MAS Bの法人は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from companies where id='0000bbbb-0000-0000-0000-0000000000c1'$q$)),
  (10,'A-MAS Bの個人情報は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from people_private where person_id='0000bbbb-0000-0000-0000-000000000002'$q$)),
  -- B(テスト株式会社B) は自分の会社だけ見える
  (11,'B-MAS 店舗2件(自社のみ)',2, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from stores$q$)),
  (12,'B-MAS 人3件(自社のみ)',3, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from people$q$)),
  (13,'B-MAS お知らせ2件(自社のみ)',2, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from notices$q$)),
  -- B は A のデータを ID 直指定しても見えない
  (14,'B-MAS Aの店舗は見えない',0, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from stores where id='55555555-0000-0000-0000-000000000001'$q$)),
  (15,'B-MAS Aの人は見えない',0, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from people where id='aaaaaaaa-0000-0000-0000-000000000005'$q$)),
  (16,'B-MAS Aの全社お知らせは見えない',0, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000001'$q$)),
  -- B アルバイトも A のお知らせは見えない（公開中でも他社は不可）
  (17,'B-アルバイト 自社の公開お知らせ1件',1, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000003',$q$select count(*) from notices$q$)),
  (18,'B-アルバイト Aの全社お知らせは見えない',0, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000003',$q$select count(*) from notices where id='77777777-0000-0000-0000-000000000001'$q$)),
  -- tenants は自分の会社の1行だけ。anon は0
  (19,'A-MAS tenants 自社1行のみ',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from tenants$q$)),
  (20,'B-MAS tenants 自社1行のみ',1, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from tenants$q$)),
  (21,'anon tenants 0件',0, pg_temp.c('anon',null,$q$select count(*) from tenants$q$)),
  (22,'anon 店舗0件',0, pg_temp.c('anon',null,$q$select count(*) from stores$q$)),
  (23,'anon 人0件',0, pg_temp.c('anon',null,$q$select count(*) from people$q$)),
  -- 対象者展開は自分の会社だけ数える
  (24,'A-MAS 対象者展開(自社の全社)=8',8, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from notice_target_person_ids('77777777-0000-0000-0000-000000000001')$q$)),
  (25,'B-MAS 対象者展開(自社の全社)=3',3, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from notice_target_person_ids('0000bbbb-0000-0000-0000-000000000071')$q$)),
  (26,'B-MAS がAのお知らせの対象者展開=0',0, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from notice_target_person_ids('77777777-0000-0000-0000-000000000001')$q$)),
  (27,'B-アルバイト 対象者展開=0(管理職でない)',0, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000003',$q$select count(*) from notice_target_person_ids('0000bbbb-0000-0000-0000-000000000071')$q$)),
  -- 書き込みは自分の会社だけ（他社テナントを指定して作れない／他社行を触れない／他社へ移せない）
  (28,'B-MAS がtenant=Aでお知らせ作成=拒否(-1)',-1, pg_temp.w('0000bbbb-0000-0000-0000-000000000001',$q$insert into notices(tenant_id,title,body) values('0000ffff-0000-0000-0000-000000000001','不正','x')$q$)),
  (29,'B-MAS がAのお知らせ編集=0行(触れない)',0, pg_temp.w('0000bbbb-0000-0000-0000-000000000001',$q$update notices set title=title where id='77777777-0000-0000-0000-000000000001'$q$)),
  (30,'A-MAS が自社店舗をBへ移動=拒否(-1)',-1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000001',$q$update stores set tenant_id='0000ffff-0000-0000-0000-000000000002' where id='55555555-0000-0000-0000-000000000001'$q$))
)
select
  (select count(*) from r)                   as 件数,
  (select count(*) from r where 期待 = 実際)  as pass,
  (select count(*) from r where 期待 <> 実際) as fail,
  case when (select count(*) from r where 期待 <> 実際) = 0
       then '✅ 全部OK（合格）'
       else '⚠ 不合格: ' || (select string_agg('['||番号||'] '||テスト||'(期待'||期待||'/実際'||実際||')', ' / ') from r where 期待 <> 実際)
  end                                        as 結果;
