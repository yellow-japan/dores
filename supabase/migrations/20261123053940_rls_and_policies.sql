-- =============================================================
-- DO'reS STEP3 — 権限（RLS）と判定関数
-- 設計の正本: yellow-brain/06_system/master-data-design.md (status: approved)
--
-- 方針:
--  - 全表で RLS を有効にする。ログインしていない人(anon)はどの表も見えない
--    （ポリシーは全て to authenticated。anon には何も許可しない）
--  - 判定関数は security definer + search_path 固定 で、RLSの再帰（ループ）を防ぐ
--    （関数の所有者=postgres は RLS を素通りして内部クエリを実行できる）
--  - 「今の権限／所属」は end_on が空 かつ start_on <= 今日 で判定する
--  - 書き込み（insert/update/delete）は当面 MAS だけ
-- =============================================================

-- -------------------------------------------------------------
-- 判定用の関数（security definer・search_path固定でループ防止）
-- -------------------------------------------------------------

-- ログイン中ユーザーに対応する people.id
create or replace function current_person_id()
returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select id from people where auth_user_id = auth.uid();
$$;

-- 本部管理者（MAS・全社）か
create or replace function is_mas()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from role_grants g
    where g.person_id = current_person_id()
      and g.role = 'MAS' and g.scope = 'all'
      and g.start_on <= current_date and g.end_on is null
  );
$$;

-- その店舗を見てよいか
--   MAS=全店 / LEA=担当店舗 / AREA=担当エリアの全店 / FC=自社のFC店 / MEM・PART=自分の所属店舗
create or replace function can_see_store(p_store_id uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select
    is_mas()
    or exists ( -- LEA（店長）: 店舗付与
      select 1 from role_grants g
      where g.person_id = current_person_id() and g.role = 'LEA' and g.scope = 'store'
        and g.scope_id = p_store_id and g.start_on <= current_date and g.end_on is null )
    or exists ( -- AREA（エリア長）: エリア付与 → そのエリアの店舗
      select 1 from role_grants g join stores s on s.id = p_store_id
      where g.person_id = current_person_id() and g.role = 'AREA' and g.scope = 'area'
        and g.scope_id = s.area_id and g.start_on <= current_date and g.end_on is null )
    or exists ( -- FC（FCオーナー）: 法人付与 → 自社のFC店
      select 1 from role_grants g join stores s on s.id = p_store_id
      where g.person_id = current_person_id() and g.role = 'FC' and g.scope = 'company'
        and g.scope_id = s.company_id and s.operation_type = 'fc'
        and g.start_on <= current_date and g.end_on is null )
    or exists ( -- MEM・PART: 現在の所属店舗
      select 1 from assignments a
      where a.person_id = current_person_id() and a.store_id = p_store_id
        and a.start_on <= current_date and a.end_on is null );
$$;

-- その人（名簿）を見てよいか
--   本人は常に見られる。MASは全員。管理職(AREA/LEA)は、見てよい店舗に現在所属している人を見られる。
--   MEM・PART（社員・アルバイト）は管理職権限が無いので、自分だけ（名簿で他人は見えない）。
create or replace function can_see_person(p_person_id uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select
    is_mas()
    or p_person_id = current_person_id()
    or exists (
      select 1
      from assignments a
      join role_grants g on g.person_id = current_person_id()
      where a.person_id = p_person_id and a.store_id is not null
        and a.start_on <= current_date and a.end_on is null
        and g.role in ('AREA','LEA')
        and g.start_on <= current_date and g.end_on is null
        and can_see_store(a.store_id) );
$$;

grant execute on function current_person_id(), is_mas(), can_see_store(uuid), can_see_person(uuid) to authenticated;

-- -------------------------------------------------------------
-- RLS 有効化（全表）
-- -------------------------------------------------------------
alter table companies          enable row level security;
alter table brands             enable row level security;
alter table areas              enable row level security;
alter table departments        enable row level security;
alter table ranks              enable row level security;
alter table stores             enable row level security;
alter table store_external_ids enable row level security;
alter table people             enable row level security;
alter table employment_history enable row level security;
alter table people_private     enable row level security;
alter table assignments        enable row level security;
alter table role_grants        enable row level security;
alter table rank_history       enable row level security;

-- -------------------------------------------------------------
-- ポリシー
--   *_sel  … 閲覧（to authenticated のみ。anonは対象外＝見えない）
--   *_write… 書き込みは MAS だけ（for all + is_mas()）。
--            for all の USING は SELECT にもOR合成されるが、MASは全閲覧でよいので問題ない
-- -------------------------------------------------------------

-- マスター参照表（法人・業態・エリア・部署・ランク）: ログイン者は閲覧可、書き込みはMAS
create policy companies_sel   on companies   for select to authenticated using (true);
create policy companies_write on companies   for all    to authenticated using (is_mas()) with check (is_mas());
create policy brands_sel      on brands       for select to authenticated using (true);
create policy brands_write    on brands       for all    to authenticated using (is_mas()) with check (is_mas());
create policy areas_sel       on areas        for select to authenticated using (true);
create policy areas_write     on areas        for all    to authenticated using (is_mas()) with check (is_mas());
create policy departments_sel on departments  for select to authenticated using (true);
create policy departments_write on departments for all   to authenticated using (is_mas()) with check (is_mas());
create policy ranks_sel       on ranks        for select to authenticated using (true);
create policy ranks_write     on ranks        for all    to authenticated using (is_mas()) with check (is_mas());

-- 店舗: can_see_store で絞る
create policy stores_sel   on stores for select to authenticated using (can_see_store(id));
create policy stores_write on stores for all    to authenticated using (is_mas()) with check (is_mas());

-- 店舗の外部連携ID: その店舗が見えるなら見える
create policy store_ext_sel   on store_external_ids for select to authenticated using (can_see_store(store_id));
create policy store_ext_write on store_external_ids for all    to authenticated using (is_mas()) with check (is_mas());

-- 人: 見てよい店舗に所属している人だけ（＋本人・MAS）
create policy people_sel   on people for select to authenticated using (can_see_person(id));
create policy people_write on people for all    to authenticated using (is_mas()) with check (is_mas());

-- 雇用区分の履歴: その人が見えるなら見える
create policy emp_hist_sel   on employment_history for select to authenticated using (can_see_person(person_id));
create policy emp_hist_write on employment_history for all    to authenticated using (is_mas()) with check (is_mas());

-- 個人情報: 本人と MAS だけ（店長でも見られない）
create policy people_private_sel   on people_private for select to authenticated using (is_mas() or person_id = current_person_id());
create policy people_private_write on people_private for all    to authenticated using (is_mas()) with check (is_mas());

-- 所属履歴: その人が見えるなら見える
create policy assignments_sel   on assignments for select to authenticated using (can_see_person(person_id));
create policy assignments_write on assignments for all    to authenticated using (is_mas()) with check (is_mas());

-- 権限: 本人と MAS だけ（権限情報は機微なため）
create policy role_grants_sel   on role_grants for select to authenticated using (is_mas() or person_id = current_person_id());
create policy role_grants_write on role_grants for all    to authenticated using (is_mas()) with check (is_mas());

-- ランク履歴: その人が見えるなら見える
create policy rank_hist_sel   on rank_history for select to authenticated using (can_see_person(person_id));
create policy rank_hist_write on rank_history for all    to authenticated using (is_mas()) with check (is_mas());

-- -------------------------------------------------------------
-- current_* ビューを更新：start_on <= 今日 も条件に加える（未来日付の予約は「今」ではない）
-- -------------------------------------------------------------
create or replace view current_assignments with (security_invoker = on) as
  select * from assignments where end_on is null and start_on <= current_date;

create or replace view current_role_grants with (security_invoker = on) as
  select * from role_grants where end_on is null and start_on <= current_date;
