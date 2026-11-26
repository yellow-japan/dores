-- =============================================================
-- DO'reS STEP2「運営の入口」確認 — dores-dev の SQL Editor に貼って1回 Run
--   ・1回の実行で全部の合否を1行にまとめて返す
--   ・データは一切変更しない（書き込みテストは内部で自動的に巻き戻す）
--   ・「会社に入る」は request.acting_tenant を立てて擬似再現（アプリの「入る」に相当）
--   前提: seed.sql・seed_notices.sql・seed_tenant_b.sql・seed_platform.sql を投入済み
--
--   登場人物（テスト用に yellow の人を運営役として流用）:
--     代表     = aaaaaaaa-...001（運営・B社に運営サポートで入れる／個人情報の許可は無し）
--     エリア長 = aaaaaaaa-...002（B社に運営サポートで入れる＋B社個人情報の期限付き許可あり）
--     店長A   = aaaaaaaa-...003（B社にコンサルの許可だが未有効＝入れない）
--     社員     = aaaaaaaa-...005（許可なし）
--     B社      = 0000ffff-...002 ／ yellow社 = 0000ffff-...001
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
  perform set_config('request.acting_tenant','',true);
  execute p_sql into n; perform set_config('role','none',true); return n;
end $f$;

-- 「会社に入った状態」で件数を数える（acting=入る会社／空=入っていない）
create function pg_temp.ca(p_sub uuid, p_acting text, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  perform set_config('request.acting_tenant', coalesce(p_acting,''), true);
  execute p_sql into n;
  perform set_config('request.acting_tenant','',true);
  perform set_config('role','none',true);
  return n;
end $f$;

-- 「会社に入った状態」で書き込みを試す（必ず巻き戻す）。許可=行数／拒否=-1。
create function pg_temp.wa(p_sub uuid, p_acting text, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  perform set_config('request.acting_tenant', coalesce(p_acting,''), true);
  begin
    execute p_sql; get diagnostics n = row_count; raise exception 'TESTROLLBACK';
  exception
    when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then n := -1; end if;
    when others then n := -1;
  end;
  perform set_config('request.acting_tenant','',true);
  perform set_config('role','none',true);
  return n;
end $f$;

with r(番号, テスト, 期待, 実際) as (values
  -- 入っていないと他社は見えない（自分の会社だけ）
  (1 ,'代表 未入: B社店舗は見えない',0, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000001', null, $q$select count(*) from stores where tenant_id='0000ffff-0000-0000-0000-000000000002'$q$)),
  (2 ,'代表 未入: 自社(yellow)店舗4',4, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000001', null, $q$select count(*) from stores$q$)),
  -- 運営サポートでB社に入ると、B社の中が見える
  (3 ,'代表 入B: 店舗2',2, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from stores$q$)),
  (4 ,'代表 入B: 人3',3, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from people$q$)),
  (5 ,'代表 入B: お知らせ2',2, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from notices$q$)),
  -- 入っても個人情報は許可が無ければ見えない
  (6 ,'代表 入B: 個人情報は見えない(許可なし)',0, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from people_private$q$)),
  -- 入っても自分の会社(yellow)は混ざらない
  (7 ,'代表 入B: 自社(yellow)店舗は混ざらない',0, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from stores where tenant_id='0000ffff-0000-0000-0000-000000000001'$q$)),
  -- エリア長は個人情報の期限付き許可があるので見える
  (8 ,'エリア長 入B: 店舗2',2, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000002','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from stores$q$)),
  (9 ,'エリア長 入B: 個人情報3(許可あり)',3, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000002','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from people_private$q$)),
  -- コンサルは未有効＝入れない（指定しても自分の会社に戻る）
  (10,'店長A コンサルでB指定: B社店舗は見えない(未有効)',0, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000003','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from stores where tenant_id='0000ffff-0000-0000-0000-000000000002'$q$)),
  (11,'店長A コンサルでB指定: 自分の会社に戻る(自店1)',1, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000003','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from stores$q$)),
  -- 許可が無い人は入れない
  (12,'社員 B指定: 許可なしでB社は見えない',0, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000005','0000ffff-0000-0000-0000-000000000002', $q$select count(*) from stores where tenant_id='0000ffff-0000-0000-0000-000000000002'$q$)),
  -- 入った記録は「入れる会社」にだけ作れる
  (13,'代表: B社へ入った記録=作成できる(1)',1, pg_temp.wa('aaaaaaaa-0000-0000-0000-000000000001', null, $q$insert into company_access_sessions(person_id,target_tenant_id,reason) values('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002','テスト')$q$)),
  (14,'店長A: コンサル未有効で入った記録=拒否(-1)',-1, pg_temp.wa('aaaaaaaa-0000-0000-0000-000000000003', null, $q$insert into company_access_sessions(person_id,target_tenant_id) values('aaaaaaaa-0000-0000-0000-000000000003','0000ffff-0000-0000-0000-000000000002')$q$)),
  (15,'社員: 許可なしで入った記録=拒否(-1)',-1, pg_temp.wa('aaaaaaaa-0000-0000-0000-000000000005', null, $q$insert into company_access_sessions(person_id,target_tenant_id) values('aaaaaaaa-0000-0000-0000-000000000005','0000ffff-0000-0000-0000-000000000002')$q$)),
  -- 許可の一覧は運営だけが全部見える
  (16,'代表(運営): 許可一覧=3件見える',3, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001', $q$select count(*) from company_access_grants$q$)),
  (17,'社員: 許可一覧=0件(運営でない)',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000005', $q$select count(*) from company_access_grants$q$)),
  -- 種類スイッチ: 運営サポートは有効・コンサルは未有効
  (18,'種類: ops_support は有効',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001', $q$select count(*) from access_kinds where kind='ops_support' and enabled$q$)),
  (19,'種類: consultant は未有効',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001', $q$select count(*) from access_kinds where kind='consultant' and enabled$q$)),
  -- 運営は業務データを書き換えられない（入っていても）
  (20,'代表 入B: B社の店舗を編集=0行(業務データ不可)',0, pg_temp.wa('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002', $q$update stores set name=name where tenant_id='0000ffff-0000-0000-0000-000000000002'$q$)),
  (21,'代表 入B: B社にお知らせ作成=拒否(-1)',-1, pg_temp.wa('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002', $q$insert into notices(tenant_id,title,body) values('0000ffff-0000-0000-0000-000000000002','x','y')$q$)),
  -- 運営は「入っている会社の設定」は変えられる
  (22,'代表 入B: B社の会社設定を変更=許可(1)',1, pg_temp.wa('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002', $q$update tenants set display_name=display_name where id='0000ffff-0000-0000-0000-000000000002'$q$)),
  (23,'社員 B指定: 会社設定変更=0行(運営でない)',0, pg_temp.wa('aaaaaaaa-0000-0000-0000-000000000005','0000ffff-0000-0000-0000-000000000002', $q$update tenants set display_name=display_name where id='0000ffff-0000-0000-0000-000000000002'$q$)),
  -- anon は運営の表も見えない
  (24,'anon: 許可一覧=0件',0, pg_temp.c('anon',null, $q$select count(*) from company_access_grants$q$)),
  -- 退出(acting=null)で自分の会社に戻る
  (25,'代表 退出後: B社店舗は見えない',0, pg_temp.ca('aaaaaaaa-0000-0000-0000-000000000001', null, $q$select count(*) from stores where tenant_id='0000ffff-0000-0000-0000-000000000002'$q$))
)
select
  (select count(*) from r)                   as 件数,
  (select count(*) from r where 期待 = 実際)  as pass,
  (select count(*) from r where 期待 <> 実際) as fail,
  case when (select count(*) from r where 期待 <> 実際) = 0
       then '✅ 全部OK（合格）'
       else '⚠ 不合格: ' || (select string_agg('['||番号||'] '||テスト||'(期待'||期待||'/実際'||実際||')', ' / ') from r where 期待 <> 実際)
  end                                        as 結果;
