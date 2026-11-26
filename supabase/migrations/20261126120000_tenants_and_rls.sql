-- =============================================================
-- DO'reS STEP1(会社ごとに分ける) — テナント(会社)の表・tenant_id・権限(RLS)
-- 設計の正本: yellow-brain/07_decisions/2026-11-23-dores-multi-company-structure.md (approved)
--
-- 方針（代表承認済みの設計）:
--  - DO'reS の下は「会社(テナント)」ごとに完全に分ける。
--  - すべての業務表に tenant_id（必須）を足し、RLS に「自分のテナントだけ」を必ず加える。
--    → 画面にバグがあっても、他社データは絶対に返らない（DB側で止める）。
--  - 新しい判定関数 current_tenant_id()（ログイン中の人の会社）を追加。
--  - 既に適用済みのマイグレーションは書き換えず、この新しい1本で足す。
--  - 既存の架空データはすべて「yellow」テナントのものにする（安全な順で backfill → NOT NULL）。
--  - tenant_id は insert 時に current_tenant_id() を既定値にし、書き込みは自テナントだけに制限。
-- =============================================================

-- -------------------------------------------------------------
-- 1. テナント（会社）の表 tenants
-- -------------------------------------------------------------
create table tenants (
  id                    uuid primary key default gen_random_uuid(),
  slug                  text not null unique,                 -- URLに使う短い名前（例 yellow）
  display_name          text not null,                        -- 会社名の表示（例 yellow.inc）
  icon_path             text,                                 -- ホーム画面アイコン（Storage）
  favicon_path          text,                                 -- タブのマーク（Storage）
  background_image_path text,                                 -- 背景イラスト（Storage）
  status                text not null default 'active'
                          check (status in ('active','preparing','suspended')),
  created_at            timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);
comment on table  tenants is 'テナント＝DO''reS を使う会社。DO''reS の直下はこの会社ごとに完全に分かれる';
comment on column tenants.slug   is 'URLに使う短い名前（例 yellow）。会社をまたいで一意';
comment on column tenants.status is '状態: active=稼働中 / preparing=準備中 / suspended=停止';

create trigger trg_tenants_updated before update on tenants for each row execute function set_updated_at();

-- -------------------------------------------------------------
-- 2. yellow テナント（既存データの入れ物）。app_settings の内容をここに移す。
--    固定ID 0000ffff-...-0001。app_settings 表自体は「移行済み・不使用」で残す（削除しない）。
-- -------------------------------------------------------------
insert into tenants (id, slug, display_name, background_image_path, status)
values (
  '0000ffff-0000-0000-0000-000000000001',
  'yellow',
  coalesce((select company_display_name  from app_settings where id = 1), 'yellow.inc'),
  (select background_image_path from app_settings where id = 1),
  'active'
)
on conflict (id) do nothing;

comment on table app_settings is '【移行済み・不使用】会社名・背景は tenants へ移行。削除せず残す。新しいコードは tenants を読む';

-- -------------------------------------------------------------
-- 3. 全業務表に tenant_id を足す（nullで追加 → yellowで埋める → NOT NULL）
--    対象: 共通マスター13表 ＋ お知らせ3表。app_settings は移行済みのため対象外。
--    ※ 既定値(current_tenant_id())は、関数を作ったあと(手順5)で設定する。
-- -------------------------------------------------------------
do $$
declare
  t    text;
  yid  constant text := '0000ffff-0000-0000-0000-000000000001';
  tbls constant text[] := array[
    'companies','brands','areas','departments','ranks','stores','store_external_ids',
    'people','employment_history','people_private','assignments','role_grants','rank_history',
    'notices','notice_targets','notice_acks'
  ];
begin
  foreach t in array tbls loop
    execute format('alter table %I add column tenant_id uuid references tenants(id) on delete restrict', t);
    execute format('update %I set tenant_id = %L where tenant_id is null', t, yid);
    execute format('alter table %I alter column tenant_id set not null', t);
    execute format('create index %I on %I(tenant_id)', 'idx_'||t||'_tenant', t);
  end loop;
end $$;

-- -------------------------------------------------------------
-- 4. 人が読むコードは「会社の中で一意」に変える（別の会社が同じコードを使える）
-- -------------------------------------------------------------
alter table stores drop constraint if exists stores_store_code_key;
alter table stores add  constraint stores_tenant_store_code_key unique (tenant_id, store_code);

alter table people drop constraint if exists people_employee_code_key;
alter table people add  constraint people_tenant_employee_code_key unique (tenant_id, employee_code);

-- -------------------------------------------------------------
-- 5. 判定関数 current_tenant_id()（ログイン中の人の会社）
--    security definer + search_path固定。anon/public からは呼べない。
-- -------------------------------------------------------------
create or replace function current_tenant_id()
returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select tenant_id from people where auth_user_id = auth.uid();
$$;

revoke execute on function current_tenant_id() from public;
revoke execute on function current_tenant_id() from anon;
grant  execute on function current_tenant_id() to authenticated;

-- 既定値: insert で tenant_id を省くと、自分の会社が入る（書き込みは手順7で自テナントに限定）
do $$
declare
  t    text;
  tbls constant text[] := array[
    'companies','brands','areas','departments','ranks','stores','store_external_ids',
    'people','employment_history','people_private','assignments','role_grants','rank_history',
    'notices','notice_targets','notice_acks'
  ];
begin
  foreach t in array tbls loop
    execute format('alter table %I alter column tenant_id set default current_tenant_id()', t);
  end loop;
end $$;

-- -------------------------------------------------------------
-- 6. tenants の RLS
--    ログイン者は「自分の会社の行」だけ見える。書き込みは DO'reS運営(STEP2)・マイグレーションで行う。
-- -------------------------------------------------------------
alter table tenants enable row level security;
create policy tenants_sel on tenants for select to authenticated using (id = current_tenant_id());

-- -------------------------------------------------------------
-- 7. 既存ポリシーを「自分のテナントだけ」を足して作り直す
--    （適用済みマイグレーションは触らず、ここで drop → create する）
--    読み取り: 先頭に tenant_id = current_tenant_id() を AND
--    書き込み: using/with check の両方に tenant_id = current_tenant_id() を AND（他社行は作れない・触れない）
-- -------------------------------------------------------------

-- マスター参照表（法人・業態・エリア・部署・ランク）
drop policy if exists companies_sel   on companies;
drop policy if exists companies_write on companies;
create policy companies_sel   on companies for select to authenticated using (tenant_id = current_tenant_id());
create policy companies_write on companies for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

drop policy if exists brands_sel   on brands;
drop policy if exists brands_write on brands;
create policy brands_sel   on brands for select to authenticated using (tenant_id = current_tenant_id());
create policy brands_write on brands for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

drop policy if exists areas_sel   on areas;
drop policy if exists areas_write on areas;
create policy areas_sel   on areas for select to authenticated using (tenant_id = current_tenant_id());
create policy areas_write on areas for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

drop policy if exists departments_sel   on departments;
drop policy if exists departments_write on departments;
create policy departments_sel   on departments for select to authenticated using (tenant_id = current_tenant_id());
create policy departments_write on departments for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

drop policy if exists ranks_sel   on ranks;
drop policy if exists ranks_write on ranks;
create policy ranks_sel   on ranks for select to authenticated using (tenant_id = current_tenant_id());
create policy ranks_write on ranks for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

-- 店舗
drop policy if exists stores_sel   on stores;
drop policy if exists stores_write on stores;
create policy stores_sel   on stores for select to authenticated using (tenant_id = current_tenant_id() and can_see_store(id));
create policy stores_write on stores for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

-- 店舗の外部連携ID
drop policy if exists store_ext_sel   on store_external_ids;
drop policy if exists store_ext_write on store_external_ids;
create policy store_ext_sel   on store_external_ids for select to authenticated using (tenant_id = current_tenant_id() and can_see_store(store_id));
create policy store_ext_write on store_external_ids for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

-- 人
drop policy if exists people_sel   on people;
drop policy if exists people_write on people;
create policy people_sel   on people for select to authenticated using (tenant_id = current_tenant_id() and can_see_person(id));
create policy people_write on people for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

-- 雇用区分の履歴
drop policy if exists emp_hist_sel   on employment_history;
drop policy if exists emp_hist_write on employment_history;
create policy emp_hist_sel   on employment_history for select to authenticated using (tenant_id = current_tenant_id() and can_see_person(person_id));
create policy emp_hist_write on employment_history for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

-- 個人情報: 本人と MAS だけ（＋自テナント）
drop policy if exists people_private_sel   on people_private;
drop policy if exists people_private_write on people_private;
create policy people_private_sel   on people_private for select to authenticated using (tenant_id = current_tenant_id() and (is_mas() or person_id = current_person_id()));
create policy people_private_write on people_private for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

-- 所属履歴
drop policy if exists assignments_sel   on assignments;
drop policy if exists assignments_write on assignments;
create policy assignments_sel   on assignments for select to authenticated using (tenant_id = current_tenant_id() and can_see_person(person_id));
create policy assignments_write on assignments for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

-- 権限: 本人と MAS だけ（＋自テナント）
drop policy if exists role_grants_sel   on role_grants;
drop policy if exists role_grants_write on role_grants;
create policy role_grants_sel   on role_grants for select to authenticated using (tenant_id = current_tenant_id() and (is_mas() or person_id = current_person_id()));
create policy role_grants_write on role_grants for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

-- ランク履歴
drop policy if exists rank_hist_sel   on rank_history;
drop policy if exists rank_hist_write on rank_history;
create policy rank_hist_sel   on rank_history for select to authenticated using (tenant_id = current_tenant_id() and can_see_person(person_id));
create policy rank_hist_write on rank_history for all    to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas());

-- お知らせ本体
drop policy if exists notices_sel on notices;
drop policy if exists notices_ins on notices;
drop policy if exists notices_upd on notices;
create policy notices_sel on notices for select to authenticated
  using ( tenant_id = current_tenant_id() and ( is_mas() or (status = 'published' and notice_is_target(id)) ) );
create policy notices_ins on notices for insert to authenticated
  with check ( tenant_id = current_tenant_id() and is_mas() );
create policy notices_upd on notices for update to authenticated
  using ( tenant_id = current_tenant_id() and is_mas() ) with check ( tenant_id = current_tenant_id() and is_mas() );

-- お知らせの対象
drop policy if exists notice_targets_sel on notice_targets;
drop policy if exists notice_targets_ins on notice_targets;
drop policy if exists notice_targets_upd on notice_targets;
create policy notice_targets_sel on notice_targets for select to authenticated using ( tenant_id = current_tenant_id() and is_mas() );
create policy notice_targets_ins on notice_targets for insert to authenticated with check ( tenant_id = current_tenant_id() and is_mas() );
create policy notice_targets_upd on notice_targets for update to authenticated using ( tenant_id = current_tenant_id() and is_mas() ) with check ( tenant_id = current_tenant_id() and is_mas() );

-- お知らせ確認
drop policy if exists notice_acks_sel on notice_acks;
drop policy if exists notice_acks_ins on notice_acks;
create policy notice_acks_sel on notice_acks for select to authenticated
  using ( tenant_id = current_tenant_id() and ( is_mas() or person_id = current_person_id() or can_see_person(person_id) ) );
create policy notice_acks_ins on notice_acks for insert to authenticated
  with check (
    tenant_id = current_tenant_id()
    and person_id = current_person_id()
    and exists (
      select 1 from notices n
      where n.id = notice_id and n.tenant_id = current_tenant_id()
        and n.status = 'published' and notice_is_target(n.id)
    )
  );

-- -------------------------------------------------------------
-- 8. 対象者展開の関数も「自分の会社だけ」にする（他社の人を数えない）
--    ・返す人は current_tenant_id() の people だけ
--    ・お知らせが自分の会社のものでなければ0件
--    ・MAS・管理職(AREA/LEA)以外が呼んだら0件（既存の安全策は維持）
-- -------------------------------------------------------------
create or replace function notice_target_person_ids(p_notice uuid)
returns setof uuid language sql stable security definer set search_path = public, pg_temp as $$
  select pp.id
  from (
    -- 全員
    select p.id as pid
    from people p
    where exists (
      select 1 from notice_targets t
      where t.notice_id = p_notice and t.active and t.target_type = 'all'
    )
    union
    -- 個人
    select t.target_id
    from notice_targets t
    where t.notice_id = p_notice and t.active and t.target_type = 'person' and t.target_id is not null
    union
    -- ランク（現在のランク）
    select p.id
    from people p
    join lateral (
      select rh.rank_id from rank_history rh
      where rh.person_id = p.id
      order by rh.achieved_on desc, rh.created_at desc
      limit 1
    ) cr on true
    where exists (
      select 1 from notice_targets t
      where t.notice_id = p_notice and t.active and t.target_type = 'rank' and t.target_id = cr.rank_id
    )
    union
    -- 店舗（現在の所属）
    select a.person_id
    from assignments a
    where a.store_id is not null and a.start_on <= current_date and a.end_on is null
      and exists (
        select 1 from notice_targets t
        where t.notice_id = p_notice and t.active and t.target_type = 'store' and t.target_id = a.store_id
      )
    union
    -- エリア（対象エリア＋配下エリア）に属する店舗の現在所属
    select a.person_id
    from assignments a
    join stores s on s.id = a.store_id
    where a.store_id is not null and a.start_on <= current_date and a.end_on is null
      and s.area_id in (
        with recursive desc_areas(id) as (
          select t.target_id
          from notice_targets t
          where t.notice_id = p_notice and t.active and t.target_type = 'area' and t.target_id is not null
          union
          select ar.id from areas ar join desc_areas d on ar.parent_area_id = d.id
        )
        select id from desc_areas
      )
  ) ids
  -- 返す人は自分の会社の people だけに限定（他社の人は数えない）
  join people pp on pp.id = ids.pid and pp.tenant_id = current_tenant_id()
  -- お知らせが自分の会社のもので、呼んだ人が MAS・管理職(AREA/LEA)のときだけ返す
  where exists (select 1 from notices n where n.id = p_notice and n.tenant_id = current_tenant_id())
    and exists (
      select 1 from role_grants g
      where g.person_id = current_person_id()
        and g.role in ('MAS', 'AREA', 'LEA')
        and g.start_on <= current_date and g.end_on is null
    );
$$;

revoke execute on function notice_target_person_ids(uuid) from public;
revoke execute on function notice_target_person_ids(uuid) from anon;
grant  execute on function notice_target_person_ids(uuid) to authenticated;
