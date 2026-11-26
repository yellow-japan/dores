-- =============================================================
-- DO'reS STEP3「機能の表示＋開発と反映」確認 — dores-dev の SQL Editor に貼って1回 Run
--   ・1回の実行で全部の合否を1行にまとめて返す
--   ・データは一切変更しない（状態切替・反映・書き込みは内部で自動的に巻き戻す）
--   前提: seed.sql・seed_notices.sql・seed_tenant_b.sql・seed_platform.sql・seed_features.sql を投入済み
--
--   登場人物:
--     代表   = aaaaaaaa-...001（DO'reS運営 platform_admin）
--     社員   = aaaaaaaa-...005（運営でない）
--     B-MAS  = 0000bbbb-...001
--     yellow = 0000ffff-...001 ／ B社 = 0000ffff-...002
--   初期設定: yellowお知らせ=使える/v1.1、Bお知らせ=使える/v1.0（Bは新バージョンに未反映）
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

create function pg_temp.w(p_sub uuid, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  perform set_config('request.acting_tenant','',true);
  begin
    execute p_sql; get diagnostics n = row_count; raise exception 'TESTROLLBACK';
  exception
    when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then n := -1; end if;
    when others then n := -1;
  end;
  perform set_config('role','none',true); return n;
end $f$;

-- 運営がB社のお知らせの状態(使える/準備中/出さない)を切り替えて、その状態でB-MASの件数を見る（巻き戻す）
create function pg_temp.gate(p_admin uuid, p_user uuid, p_state text, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.acting_tenant','',true);
  begin
    perform set_config('request.jwt.claims', json_build_object('sub',p_admin,'role','authenticated')::text, true);
    update tenant_features set state=p_state
      where tenant_id='0000ffff-0000-0000-0000-000000000002' and feature_key='notices';
    perform set_config('request.jwt.claims', json_build_object('sub',p_user,'role','authenticated')::text, true);
    execute p_sql into n;
    raise exception 'TESTROLLBACK';
  exception
    when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then n := -1; end if;
  end;
  perform set_config('role','none',true); return n;
end $f$;

-- 運営がB社に新バージョンを反映して、その後の判定を見る（巻き戻す）
create function pg_temp.reflect(p_admin uuid, p_to text, p_sql text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.acting_tenant','',true);
  begin
    perform set_config('request.jwt.claims', json_build_object('sub',p_admin,'role','authenticated')::text, true);
    update tenant_features set enabled_version=p_to
      where tenant_id='0000ffff-0000-0000-0000-000000000002' and feature_key='notices';
    execute p_sql into n;
    raise exception 'TESTROLLBACK';
  exception
    when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then n := -1; end if;
  end;
  perform set_config('role','none',true); return n;
end $f$;

-- 指定ユーザーで「書き込み(p_do)」→「確認(p_check)の件数」を取り、必ず巻き戻す。p_doが拒否なら-1。
create function pg_temp.tx(p_sub uuid, p_do text, p_check text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.jwt.claims', json_build_object('sub',p_sub,'role','authenticated')::text, true);
  perform set_config('request.acting_tenant','',true);
  begin
    execute p_do;
    execute p_check into n;
    raise exception 'TESTROLLBACK';
  exception
    when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then n := -1; end if;
    when others then n := -1;
  end;
  perform set_config('role','none',true); return n;
end $f$;

-- adminが書き込み(p_do)→別ユーザー(p_user)で確認(p_check)の件数。必ず巻き戻す。
create function pg_temp.tx2(p_admin uuid, p_do text, p_user uuid, p_check text) returns int language plpgsql as $f$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('request.acting_tenant','',true);
  begin
    perform set_config('request.jwt.claims', json_build_object('sub',p_admin,'role','authenticated')::text, true);
    execute p_do;
    perform set_config('request.jwt.claims', json_build_object('sub',p_user,'role','authenticated')::text, true);
    execute p_check into n;
    raise exception 'TESTROLLBACK';
  exception
    when sqlstate 'P0001' then if sqlerrm <> 'TESTROLLBACK' then n := -1; end if;
    when others then n := -1;
  end;
  perform set_config('role','none',true); return n;
end $f$;

with r(番号, テスト, 期待, 実際) as (values
  -- カタログ（機能・層）
  (1 ,'機能カタログに お知らせ がある',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from features where key='notices'$q$)),
  (2 ,'層は4つ(THINKING/DOING/FUTURE/土台)',4, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from feature_layers$q$)),
  (3 ,'お知らせの層=THINKING(考える・学ぶ)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from features where key='notices' and layer='THINKING'$q$)),
  (4 ,'お知らせの段階=完成(done)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from features where key='notices' and stage='done'$q$)),
  -- 会社ごとの状態
  (5 ,'yellow お知らせ=使える',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select (feature_available('0000ffff-0000-0000-0000-000000000001','notices'))::int$q$)),
  (6 ,'B お知らせ=使える',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select (feature_available('0000ffff-0000-0000-0000-000000000002','notices'))::int$q$)),
  (7 ,'yellow シフト=準備中',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from tenant_features where tenant_id='0000ffff-0000-0000-0000-000000000001' and feature_key='shifts' and state='preparing'$q$)),
  (8 ,'B レポート=出さない',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from tenant_features where tenant_id='0000ffff-0000-0000-0000-000000000002' and feature_key='reports' and state='hidden'$q$)),
  -- 開発と反映: 反映していない会社には新バージョンが出ない
  (9 ,'yellow は最新版(v1.1)',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from features f where f.key='notices' and exists(select 1 from tenant_features tf where tf.tenant_id='0000ffff-0000-0000-0000-000000000001' and tf.feature_key='notices' and tf.enabled_version=f.current_version)$q$)),
  (10,'B は新バージョンが出ていない(未反映=0)',0, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from features f where f.key='notices' and exists(select 1 from tenant_features tf where tf.tenant_id='0000ffff-0000-0000-0000-000000000002' and tf.feature_key='notices' and tf.enabled_version=f.current_version)$q$)),
  (11,'反映するとBも最新版(v1.1)になる',1, pg_temp.reflect('aaaaaaaa-0000-0000-0000-000000000001','v1.1',$q$select count(*) from features f where f.key='notices' and exists(select 1 from tenant_features tf where tf.tenant_id='0000ffff-0000-0000-0000-000000000002' and tf.feature_key='notices' and tf.enabled_version=f.current_version)$q$)),
  -- DBで遮断: 準備中/出さない の会社ではお知らせが0件（URL直打ちでも）
  (12,'B 使える: B-MAS お知らせ2件',2, pg_temp.gate('aaaaaaaa-0000-0000-0000-000000000001','0000bbbb-0000-0000-0000-000000000001','available',$q$select count(*) from notices$q$)),
  (13,'B 準備中: B-MAS お知らせ0件(遮断)',0, pg_temp.gate('aaaaaaaa-0000-0000-0000-000000000001','0000bbbb-0000-0000-0000-000000000001','preparing',$q$select count(*) from notices$q$)),
  (14,'B 出さない: B-MAS お知らせ0件(遮断)',0, pg_temp.gate('aaaaaaaa-0000-0000-0000-000000000001','0000bbbb-0000-0000-0000-000000000001','hidden',$q$select count(*) from notices$q$)),
  (15,'B 準備中: 特定IDを直指定しても0件',0, pg_temp.gate('aaaaaaaa-0000-0000-0000-000000000001','0000bbbb-0000-0000-0000-000000000001','preparing',$q$select count(*) from notices where id='0000bbbb-0000-0000-0000-000000000071'$q$)),
  -- 変更は運営だけ
  (16,'運営(代表) は状態を変更できる(1)',1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000001',$q$update tenant_features set state=state where tenant_id='0000ffff-0000-0000-0000-000000000002' and feature_key='notices'$q$)),
  (17,'社員 は状態を変更できない(0行)',0, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000005',$q$update tenant_features set state=state where tenant_id='0000ffff-0000-0000-0000-000000000002' and feature_key='notices'$q$)),
  (18,'運営 は反映記録を作れる(1)',1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000001',$q$insert into feature_reflections(tenant_id,feature_key,from_version,to_version,reflected_by) values('0000ffff-0000-0000-0000-000000000002','notices','v1.0','v1.1','aaaaaaaa-0000-0000-0000-000000000001')$q$)),
  (19,'社員 は反映記録を作れない(-1)',-1, pg_temp.w('aaaaaaaa-0000-0000-0000-000000000005',$q$insert into feature_reflections(tenant_id,feature_key,to_version) values('0000ffff-0000-0000-0000-000000000002','notices','v1.1')$q$)),
  -- 見える範囲
  (20,'B-MAS は自社の機能状態3件が見える',3, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from tenant_features$q$)),
  (21,'B-MAS は他社(yellow)の機能状態は見えない',0, pg_temp.c('auth','0000bbbb-0000-0000-0000-000000000001',$q$select count(*) from tenant_features where tenant_id='0000ffff-0000-0000-0000-000000000001'$q$)),
  (22,'社員(yellow) は自社の機能状態3件が見える',3, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000005',$q$select count(*) from tenant_features$q$)),
  (23,'anon は機能カタログも見えない(0)',0, pg_temp.c('anon',null,$q$select count(*) from features$q$)),
  -- 層は「分類」＝説明が入っている（開発の進み具合ではない）
  (24,'層THINKINGに分類の説明がある',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from feature_layers where layer='THINKING' and description is not null$q$)),
  -- 土台の層と「必ず入る」印
  (25,'土台(FOUNDATION)があり required=true',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from feature_layers where layer='FOUNDATION' and required$q$)),
  (26,'必須(required)の層は土台だけ',1, pg_temp.c('auth','aaaaaaaa-0000-0000-0000-000000000001',$q$select count(*) from feature_layers where required$q$)),
  -- 層ごとの一括導入（運営のみ・記録に残る）
  (27,'運営: DOINGを一括「使える」→Bのシフトが使えるになる',1, pg_temp.tx('aaaaaaaa-0000-0000-0000-000000000001', $q$select platform_apply_layer('0000ffff-0000-0000-0000-000000000002','DOING','available')$q$, $q$select count(*) from tenant_features where tenant_id='0000ffff-0000-0000-0000-000000000002' and feature_key='shifts' and state='available'$q$)),
  (28,'運営: 一括導入は記録に残る(layer_apply)',1, pg_temp.tx('aaaaaaaa-0000-0000-0000-000000000001', $q$select platform_apply_layer('0000ffff-0000-0000-0000-000000000002','DOING','available')$q$, $q$select count(*) from feature_admin_log where action='layer_apply'$q$)),
  (29,'社員: 一括導入はできない(-1)',-1, pg_temp.tx('aaaaaaaa-0000-0000-0000-000000000005', $q$select platform_apply_layer('0000ffff-0000-0000-0000-000000000002','DOING','available')$q$, $q$select 0$q$)),
  -- 層の改名・機能の付け替えも記録に残る（運営のみ）
  (30,'運営: 層の改名は記録に残る(layer_rename)',1, pg_temp.tx('aaaaaaaa-0000-0000-0000-000000000001', $q$update feature_layers set label='DOING(改名テスト)' where layer='DOING'$q$, $q$select count(*) from feature_admin_log where action='layer_rename'$q$)),
  (31,'運営: 機能の層の付け替えは記録に残る(feature_layer_change)',1, pg_temp.tx('aaaaaaaa-0000-0000-0000-000000000001', $q$update features set layer='FUTURE' where key='notices'$q$, $q$select count(*) from feature_admin_log where action='feature_layer_change'$q$)),
  (32,'社員: 層を改名できない(記録も残らない=0)',0, pg_temp.tx('aaaaaaaa-0000-0000-0000-000000000005', $q$update feature_layers set label='x' where layer='DOING'$q$, $q$select count(*) from feature_admin_log where action='layer_rename'$q$)),
  -- 操作記録は運営だけが見える（社員は見えない）
  (33,'社員は操作記録が見えない(adminが作っても0)',0, pg_temp.tx2('aaaaaaaa-0000-0000-0000-000000000001', $q$select platform_apply_layer('0000ffff-0000-0000-0000-000000000002','DOING','available')$q$, 'aaaaaaaa-0000-0000-0000-000000000005', $q$select count(*) from feature_admin_log$q$))
)
select
  (select count(*) from r)                   as 件数,
  (select count(*) from r where 期待 = 実際)  as pass,
  (select count(*) from r where 期待 <> 実際) as fail,
  case when (select count(*) from r where 期待 <> 実際) = 0
       then '✅ 全部OK（合格）'
       else '⚠ 不合格: ' || (select string_agg('['||番号||'] '||テスト||'(期待'||期待||'/実際'||実際||')', ' / ') from r where 期待 <> 実際)
  end                                        as 結果;
