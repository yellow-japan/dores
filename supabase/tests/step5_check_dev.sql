-- =============================================================
-- DO'reS STEP5「URL対応＋運営のWeb閲覧」確認 — dores-dev の SQL Editor に貼って1回 Run
--   前提: seed 一式（…seed_features.sql まで）投入済み／STEP5マイグレーション適用済み
--   代表 = aaaaaaaa-...001 ／ B社 = 0000ffff-...002 ／ yellow = 0000ffff-...001
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

-- 関数を呼べるか（呼べたら0 / 権限エラーなら-1）
create function pg_temp.tc(p_role text, p_sub uuid, p_sql text) returns int language plpgsql as $f$
begin
  if p_role = 'anon' then
    perform set_config('role','anon',true); perform set_config('request.jwt.claims','',true);
  else
    perform set_config('role','authenticated',true);
    perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  end if;
  begin execute p_sql; perform set_config('role','none',true); return 0;
  exception when others then perform set_config('role','none',true); return -1; end;
end $f$;

-- 「入室記録を開いて」から件数（運営がWebで会社に入った状態の再現）。必ず巻き戻す。
create function pg_temp.ec(p_sub uuid, p_target text, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  begin
    if p_target is not null then
      begin insert into company_access_sessions(person_id, target_tenant_id) values (p_sub, p_target::uuid);
      exception when others then null; end;
    end if;
    execute p_sql into n;
    raise exception 'TESTROLLBACK';
  exception when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then n := -1; end if;
  end;
  perform set_config('role','none',true); return n;
end $f$;

with r(番号, テスト, 期待, 実際) as (values
  -- URL↔テナントの対応（データ化・追加7）
  (1 ,'dores-home は運営(platform)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from host_branding('dores-home.vercel.app') where kind='platform'$q$)),
  (2 ,'yellow-dores は会社(yellow)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from host_branding('yellow-dores.vercel.app') where kind='tenant' and tenant_id='0000ffff-0000-0000-0000-000000000001'$q$)),
  (3 ,'dores-ruby も会社(yellow)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from host_branding('dores-ruby.vercel.app') where kind='tenant'$q$)),
  (4 ,'未登録URLは0件(入れない)',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from host_branding('nope.example.com')$q$)),
  (5 ,'未ログインでも host_branding は会社名を取れる',1, pg_temp.c('anon',null,$q$select count(*) from host_branding('yellow-dores.vercel.app')$q$)),
  (6 ,'未ログインは対応表の全件は取れるが他社名は晒さない(1件ずつ取得)',1, pg_temp.c('anon',null,$q$select count(*) from host_branding('dores-home.vercel.app')$q$)),
  -- my_person（acting中でも自分を取れる・anon不可）
  (7 ,'代表 my_person=1件',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from my_person()$q$)),
  (8 ,'anon は my_person を呼べない(-1)',-1, pg_temp.tc('anon',null,$q$select count(*) from my_person()$q$)),
  -- 運営がWebで会社に入った状態（入室記録を開く）→ その会社の中が見える（GUCなし）
  (9 ,'代表 未入: B社店舗0',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from stores where tenant_id='0000ffff-0000-0000-0000-000000000002'$q$)),
  (10,'代表 入B(記録): B社店舗2',2, pg_temp.ec('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002',$q$select count(*) from stores$q$)),
  (11,'代表 入B(記録): B社お知らせ2',2, pg_temp.ec('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002',$q$select count(*) from notices$q$)),
  (12,'代表 入B(記録)でも自分の名前は取れる(my_person=1)',1, pg_temp.ec('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002',$q$select count(*) from my_person()$q$)),
  (13,'代表 入B(記録): 自社(yellow)店舗は混ざらない',0, pg_temp.ec('aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002',$q$select count(*) from stores where tenant_id='0000ffff-0000-0000-0000-000000000001'$q$))
)
select
  (select count(*) from r)                   as 件数,
  (select count(*) from r where 期待 = 実際)  as pass,
  (select count(*) from r where 期待 <> 実際) as fail,
  case when (select count(*) from r where 期待 <> 実際) = 0
       then '✅ 全部OK（合格）'
       else '⚠ 不合格: ' || (select string_agg('['||番号||'] '||テスト||'(期待'||期待||'/実際'||実際||')', ' / ') from r where 期待 <> 実際)
  end                                        as 結果;
