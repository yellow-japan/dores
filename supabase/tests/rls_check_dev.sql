-- =============================================================
-- DO'reS 権限(RLS) 最終確認 — dores-dev の SQL Editor に貼って「1回」Run
--   ・テスト①〜⑨を1回の実行で確認し、結果を1つの表で返す
--   ・データは一切変更しない（書き込みテストは内部で自動的に巻き戻す）
--   ・service_role ではなく authenticated ロールを擬似再現して確認する
--     （パスワードは不要。人の auth_user_id を JWT の sub にして擬似ログイン）
-- =============================================================

-- 読み取り確認用（指定ユーザーとして count を取る）
create function pg_temp.c(p_role text, p_sub uuid, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  if p_role = 'anon' then
    perform set_config('role','anon',true);
    perform set_config('request.jwt.claims','',true);
  else
    perform set_config('role','authenticated',true);
    perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  end if;
  execute p_sql into n;
  perform set_config('role','none',true);
  return n;
end $f$;

-- 書き込み確認用（指定ユーザーで書き込みを試し、必ず巻き戻す）
--   返り値: 更新できた行数 / 例外で拒否された場合は -1
create function pg_temp.w(p_sub uuid, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  begin
    execute p_sql;
    get diagnostics n = row_count;
    raise exception 'TESTROLLBACK';   -- 変更を永続化しないため強制的に巻き戻す
  exception
    when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then n := -1; end if;
    when others then n := -1;          -- RLS拒否(insert等)
  end;
  perform set_config('role','none',true);
  return n;
end $f$;

with r(番号, テスト, 期待, 実際) as (values
  (1,'① anon stores(未ログイン)',0, pg_temp.c('anon',null,$q$select count(*) from stores$q$)),
  (2,'① anon people',0, pg_temp.c('anon',null,$q$select count(*) from people$q$)),
  (3,'① anon people_private',0, pg_temp.c('anon',null,$q$select count(*) from people_private$q$)),
  (4,'② MAS stores',4, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from stores$q$)),
  (5,'② MAS people',8, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from people$q$)),
  (6,'② MAS people_private',8, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from people_private$q$)),
  (7,'③ 店長A stores(自店Aのみ)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from stores$q$)),
  (8,'③ 店長A 店舗Bは見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from stores where id='55555555-0000-0000-0000-000000000002'$q$)),
  (9,'③ 店長A people(A所属3人)',3, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from people$q$)),
  (10,'③ 店長A people_private自分のみ',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000003',$q$select count(*) from people_private$q$)),
  (11,'④ エリア長 stores(東A・B)',2, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000002',$q$select count(*) from stores$q$)),
  (12,'④ エリア長 店舗C(西)は見えない',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000002',$q$select count(*) from stores where id='55555555-0000-0000-0000-000000000003'$q$)),
  (13,'④ エリア長 people(A・B所属6人)',6, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000002',$q$select count(*) from people$q$)),
  (14,'⑤ アルバイト1 people自分のみ',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000006',$q$select count(*) from people$q$)),
  (15,'⑤ アルバイト1 people_private自分のみ',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000006',$q$select count(*) from people_private$q$)),
  (16,'⑥ 社員 stores(自店Aのみ)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000005',$q$select count(*) from stores$q$)),
  (17,'⑥ 社員 未来日付のB権限は無効',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000005',$q$select count(*) from stores where id='55555555-0000-0000-0000-000000000002'$q$)),
  (18,'⑦ FCオーナー stores(FC店Dのみ)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000008',$q$select count(*) from stores$q$)),
  (19,'⑦ FCオーナー 店舗Dが見える',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000008',$q$select count(*) from stores where id='55555555-0000-0000-0000-000000000004'$q$)),
  (20,'⑧ 店長A 店舗更新=拒否(0行)',0, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000003',$q$update stores set name=name where id='55555555-0000-0000-0000-000000000001'$q$)),
  (21,'⑧ 店長A 店舗追加=拒否(-1)',-1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000003',$q$insert into stores(store_code,name,brand_id,company_id,operation_type) values('X999','不正','bbbbbbbb-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001','direct')$q$)),
  (22,'⑧ アルバイト1 人追加=拒否(-1)',-1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000006',$q$insert into people(employee_code,display_name) values('X999','不正')$q$)),
  (23,'⑨ MAS 店舗更新=許可(1行)',1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000001',$q$update stores set name=name where id='55555555-0000-0000-0000-000000000001'$q$))
)
select
  (select count(*) from r)                        as 件数,
  (select count(*) from r where 期待 = 実際)       as pass,
  (select count(*) from r where 期待 <> 実際)      as fail,
  case when (select count(*) from r where 期待 <> 実際) = 0
       then '✅ 全部OK（合格）'
       else '⚠ 不合格: ' || (select string_agg(テスト, ' / ') from r where 期待 <> 実際)
  end                                             as 結果;
