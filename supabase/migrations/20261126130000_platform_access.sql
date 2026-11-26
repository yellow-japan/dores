-- =============================================================
-- DO'reS STEP2(運営の入口) — 所属以外の会社に入るための「1つの仕組み」
-- 設計: yellow-brain/07_decisions/2026-11-23-dores-multi-company-structure.md (approved)
--       ＋ 追加指示(追加1〜5)。STEP0回答: 運営は「見る＋設定変更」のみ／1ログイン=1会社の1人／
--          個人情報は会社MASの期限付き許可の間だけ。
--
-- 方針:
--  - 「所属以外の企業に入る許可」を1つの表 company_access_grants で表す。
--    種類 access_kind で 運営サポート(ops_support) と コンサル担当(consultant) を区別。
--  - 今回“動かす”のは ops_support だけ。consultant は表・種類・テストの準備のみ（access_kinds.enabled=false で未有効）。
--  - 入った会社だけが見える: current_acting_tenant_id()。有効な許可が無ければ必ず自分の会社に戻る（DBで保証）。
--  - 入った記録 company_access_sessions / 操作記録 company_access_actions。
--  - 個人情報(people_private)は、入っただけでは見えない。会社MASの期限付き許可(private_access_grants)の間だけ。
--  - 運営は業務データを書き換えない（書き込みは今までどおり自分の会社のMASだけ）。会社の設定(tenants行)だけ運営が変更可。
--  - 既存の適用済みマイグレーションは変更しない。SELECTポリシーは作り直す（他社混在を防ぐため write は for all をやめ ins/upd/del に分割）。
-- =============================================================

-- -------------------------------------------------------------
-- 1. 入る許可の種類 access_kinds（運営サポート／コンサル担当）。enabled で有効/準備中を切替。
-- -------------------------------------------------------------
create table access_kinds (
  kind       text primary key,
  label      text not null,
  enabled    boolean not null default false,   -- true=いま動く / false=準備だけ
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table access_kinds is '所属以外の会社に入る許可の種類。enabled=true の種類だけが実際に入れる（運営サポートのみ有効）';
create trigger trg_access_kinds_updated before update on access_kinds for each row execute function set_updated_at();

insert into access_kinds (kind, label, enabled, sort_order) values
  ('ops_support','運営サポート', true , 1),
  ('consultant' ,'コンサル担当', false, 2)
on conflict (kind) do nothing;

-- -------------------------------------------------------------
-- 2. DO'reS運営スタッフ platform_admins（許可を作る・会社設定を変える権限を持つ人）
-- -------------------------------------------------------------
create table platform_admins (
  person_id  uuid primary key references people(id) on delete restrict,
  note       text,
  created_at timestamptz not null default now()
);
comment on table platform_admins is 'DO''reS運営スタッフ（最初は代表のみ）。会社に入る許可の発行・会社設定の変更ができる';

-- -------------------------------------------------------------
-- 3. 所属以外の会社に入る許可 company_access_grants（運営サポート/コンサル共通の1つの仕組み）
-- -------------------------------------------------------------
create table company_access_grants (
  id               uuid primary key default gen_random_uuid(),
  person_id        uuid not null references people(id) on delete restrict,
  target_tenant_id uuid not null references tenants(id) on delete restrict,
  access_kind      text not null references access_kinds(kind) on delete restrict,
  reason           text,
  granted_by       uuid references people(id) on delete set null,
  status           text not null default 'active' check (status in ('active','revoked')),
  start_on         date not null default current_date,
  end_on           date,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
comment on table company_access_grants is '所属以外の会社に入る許可。種類(access_kind)で運営サポート/コンサルを区別。有効な種類のものだけ実際に入れる';
create index idx_cag_person on company_access_grants(person_id);
create index idx_cag_target on company_access_grants(target_tenant_id);
create trigger trg_cag_updated before update on company_access_grants for each row execute function set_updated_at();

-- 「所属以外のみ」: 自分の所属会社には許可を作れない
create or replace function check_access_grant_not_home()
returns trigger language plpgsql as $$
begin
  if exists (select 1 from people p where p.id = new.person_id and p.tenant_id = new.target_tenant_id) then
    raise exception '所属している会社には入る許可を作れません（所属以外のみ）';
  end if;
  return new;
end $$;
create trigger trg_cag_not_home before insert or update on company_access_grants
  for each row execute function check_access_grant_not_home();

-- -------------------------------------------------------------
-- 4. 個人情報の期限付き許可 private_access_grants（会社MASが発行）
-- -------------------------------------------------------------
create table private_access_grants (
  id               uuid primary key default gen_random_uuid(),
  person_id        uuid not null references people(id) on delete restrict,   -- 見られるようになる運営スタッフ
  target_tenant_id uuid not null references tenants(id) on delete restrict,  -- どの会社の個人情報か
  granted_by       uuid references people(id) on delete set null,            -- 許可した会社MAS
  status           text not null default 'active' check (status in ('active','revoked')),
  start_on         date not null default current_date,
  end_on           date,                                                     -- 空=無期限（通常は期限を入れる）
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
comment on table private_access_grants is '個人情報(people_private)を運営スタッフに見せる許可。会社MASが期限付きで発行。期限切れで自動的に見えなくなる';
create index idx_pag_person on private_access_grants(person_id);
create index idx_pag_target on private_access_grants(target_tenant_id);
create trigger trg_pag_updated before update on private_access_grants for each row execute function set_updated_at();

-- -------------------------------------------------------------
-- 5. 入った記録 / 操作記録
-- -------------------------------------------------------------
create table company_access_sessions (
  id               uuid primary key default gen_random_uuid(),
  person_id        uuid not null references people(id) on delete restrict,
  target_tenant_id uuid not null references tenants(id) on delete restrict,
  reason           text,
  entered_at       timestamptz not null default now(),
  exited_at        timestamptz,
  created_at       timestamptz not null default now()
);
comment on table company_access_sessions is 'DO''reS運営が会社に入った記録（入った時刻・出た時刻・理由）';
create index idx_cas_person on company_access_sessions(person_id);
create index idx_cas_target on company_access_sessions(target_tenant_id);

create table company_access_actions (
  id               uuid primary key default gen_random_uuid(),
  person_id        uuid not null references people(id) on delete restrict,
  target_tenant_id uuid not null references tenants(id) on delete restrict,
  action           text not null,
  detail           text,
  at               timestamptz not null default now()
);
comment on table company_access_actions is 'DO''reS運営が会社の中で行った操作の記録';
create index idx_caa_person on company_access_actions(person_id);
create index idx_caa_target on company_access_actions(target_tenant_id);

-- -------------------------------------------------------------
-- 6. 判定関数（security definer・search_path固定・anon不可）
-- -------------------------------------------------------------

create or replace function is_platform_admin()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from platform_admins pa where pa.person_id = current_person_id());
$$;

-- 有効(enabled)な種類の、今有効な許可があるか（＝その会社に入れるか）
create or replace function can_enter_tenant(p_target uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1
    from company_access_grants g
    join access_kinds k on k.kind = g.access_kind and k.enabled
    where g.person_id = current_person_id()
      and g.target_tenant_id = p_target
      and g.status = 'active'
      and g.start_on <= current_date and (g.end_on is null or g.end_on >= current_date)
  );
$$;

-- その会社の個人情報を見る許可が今あるか
create or replace function has_private_access(p_target uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1
    from private_access_grants pg
    where pg.person_id = current_person_id()
      and pg.target_tenant_id = p_target
      and pg.status = 'active'
      and pg.start_on <= current_date and (pg.end_on is null or pg.end_on >= current_date)
  );
$$;

-- 今「どの会社として」動いているか。
--   request.acting_tenant（アプリが「入る」で設定）が指す会社に、有効な許可があればその会社。
--   無ければ必ず自分の所属会社に戻る（DBで保証：画面が何を言っても、許可が無ければ他社にはならない）。
create or replace function current_acting_tenant_id()
returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce(
    (
      select t.id
      from tenants t
      where t.id = nullif(current_setting('request.acting_tenant', true), '')::uuid
        and can_enter_tenant(t.id)
      limit 1
    ),
    current_tenant_id()
  );
$$;

-- いま所属以外の会社に入っているか
create or replace function is_acting_cross_tenant()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select current_acting_tenant_id() is distinct from current_tenant_id();
$$;

revoke execute on function is_platform_admin(), can_enter_tenant(uuid), has_private_access(uuid), current_acting_tenant_id(), is_acting_cross_tenant() from public;
revoke execute on function is_platform_admin(), can_enter_tenant(uuid), has_private_access(uuid), current_acting_tenant_id(), is_acting_cross_tenant() from anon;
grant  execute on function is_platform_admin(), can_enter_tenant(uuid), has_private_access(uuid), current_acting_tenant_id(), is_acting_cross_tenant() to authenticated;

-- -------------------------------------------------------------
-- 7. 新しい表の RLS
-- -------------------------------------------------------------
alter table access_kinds           enable row level security;
alter table platform_admins        enable row level security;
alter table company_access_grants  enable row level security;
alter table private_access_grants  enable row level security;
alter table company_access_sessions enable row level security;
alter table company_access_actions  enable row level security;

-- access_kinds: カタログ。ログイン者は読める。変更は運営のみ。
create policy access_kinds_sel on access_kinds for select to authenticated using (true);
create policy access_kinds_upd on access_kinds for update to authenticated using (is_platform_admin()) with check (is_platform_admin());

-- platform_admins: 運営スタッフ名簿。運営 or 本人が見える。追加・変更は運営のみ。
create policy platform_admins_sel on platform_admins for select to authenticated using (is_platform_admin() or person_id = current_person_id());
create policy platform_admins_ins on platform_admins for insert to authenticated with check (is_platform_admin());
create policy platform_admins_del on platform_admins for delete to authenticated using (is_platform_admin());

-- company_access_grants: 本人 or 運営が見える。発行・変更は運営のみ。
create policy cag_sel on company_access_grants for select to authenticated using (person_id = current_person_id() or is_platform_admin());
create policy cag_ins on company_access_grants for insert to authenticated with check (is_platform_admin());
create policy cag_upd on company_access_grants for update to authenticated using (is_platform_admin()) with check (is_platform_admin());

-- private_access_grants: 本人(運営) or 運営 or 発行した会社のMAS が見える。発行は対象会社のMAS。取消は運営 or 対象会社MAS。
create policy pag_sel on private_access_grants for select to authenticated
  using (person_id = current_person_id() or is_platform_admin() or (is_mas() and current_tenant_id() = target_tenant_id));
create policy pag_ins on private_access_grants for insert to authenticated
  with check (is_mas() and current_tenant_id() = target_tenant_id);
create policy pag_upd on private_access_grants for update to authenticated
  using (is_platform_admin() or (is_mas() and current_tenant_id() = target_tenant_id))
  with check (is_platform_admin() or (is_mas() and current_tenant_id() = target_tenant_id));

-- 入った記録: 本人 or 運営が見える。作成は「入れる会社」に対して本人のみ。出た時刻の更新は本人。
create policy cas_sel on company_access_sessions for select to authenticated using (person_id = current_person_id() or is_platform_admin());
create policy cas_ins on company_access_sessions for insert to authenticated with check (person_id = current_person_id() and can_enter_tenant(target_tenant_id));
create policy cas_upd on company_access_sessions for update to authenticated using (person_id = current_person_id()) with check (person_id = current_person_id());

-- 操作記録: 本人 or 運営が見える。作成は本人のみ。
create policy caa_sel on company_access_actions for select to authenticated using (person_id = current_person_id() or is_platform_admin());
create policy caa_ins on company_access_actions for insert to authenticated with check (person_id = current_person_id());

-- -------------------------------------------------------------
-- 8. 業務表の SELECT ポリシーを「今いる会社(acting)」基準に作り直す
--    ・自分の会社にいるとき: 今までどおり（can_see_* で絞る）
--    ・所属以外に入っているとき(is_acting_cross_tenant): その会社の中は一通り見える（運営サポートの閲覧）
--    ・個人情報だけは例外: 入っていても「期限付き許可」が無ければ見えない
-- -------------------------------------------------------------
drop policy if exists companies_sel   on companies;
create policy companies_sel   on companies   for select to authenticated using (tenant_id = current_acting_tenant_id());
drop policy if exists brands_sel      on brands;
create policy brands_sel      on brands      for select to authenticated using (tenant_id = current_acting_tenant_id());
drop policy if exists areas_sel       on areas;
create policy areas_sel       on areas       for select to authenticated using (tenant_id = current_acting_tenant_id());
drop policy if exists departments_sel on departments;
create policy departments_sel on departments for select to authenticated using (tenant_id = current_acting_tenant_id());
drop policy if exists ranks_sel       on ranks;
create policy ranks_sel       on ranks       for select to authenticated using (tenant_id = current_acting_tenant_id());

drop policy if exists stores_sel on stores;
create policy stores_sel on stores for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or can_see_store(id)));

drop policy if exists store_ext_sel on store_external_ids;
create policy store_ext_sel on store_external_ids for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or can_see_store(store_id)));

drop policy if exists people_sel on people;
create policy people_sel on people for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or can_see_person(id)));

drop policy if exists emp_hist_sel on employment_history;
create policy emp_hist_sel on employment_history for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or can_see_person(person_id)));

-- 個人情報: 自分の会社では本人/MAS。所属以外に入っているときは「期限付き許可」がある間だけ。
drop policy if exists people_private_sel on people_private;
create policy people_private_sel on people_private for select to authenticated
  using (
    tenant_id = current_acting_tenant_id()
    and (
      (not is_acting_cross_tenant() and (is_mas() or person_id = current_person_id()))
      or
      (is_acting_cross_tenant() and has_private_access(current_acting_tenant_id()))
    )
  );

drop policy if exists assignments_sel on assignments;
create policy assignments_sel on assignments for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or can_see_person(person_id)));

drop policy if exists role_grants_sel on role_grants;
create policy role_grants_sel on role_grants for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or is_mas() or person_id = current_person_id()));

drop policy if exists rank_hist_sel on rank_history;
create policy rank_hist_sel on rank_history for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or can_see_person(person_id)));

drop policy if exists notices_sel on notices;
create policy notices_sel on notices for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or is_mas() or (status = 'published' and notice_is_target(id))));

drop policy if exists notice_targets_sel on notice_targets;
create policy notice_targets_sel on notice_targets for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or is_mas()));

drop policy if exists notice_acks_sel on notice_acks;
create policy notice_acks_sel on notice_acks for select to authenticated
  using (tenant_id = current_acting_tenant_id() and (is_acting_cross_tenant() or is_mas() or person_id = current_person_id() or can_see_person(person_id)));

-- -------------------------------------------------------------
-- 9. 業務表の write（STEP1は for all）を ins/upd/del に分割する
--    （for all の USING は SELECT にも効き、運営が他社に入ったとき自分の会社の行がSELECTに混ざるため）
--    書き込みは今までどおり「自分の会社の MAS だけ」。運営は他社の業務データを書き換えられない。
-- -------------------------------------------------------------
do $$
declare rec record;
begin
  for rec in
    select * from (values
      ('companies','companies_write'),
      ('brands','brands_write'),
      ('areas','areas_write'),
      ('departments','departments_write'),
      ('ranks','ranks_write'),
      ('stores','stores_write'),
      ('store_external_ids','store_ext_write'),
      ('people','people_write'),
      ('employment_history','emp_hist_write'),
      ('people_private','people_private_write'),
      ('assignments','assignments_write'),
      ('role_grants','role_grants_write'),
      ('rank_history','rank_hist_write')
    ) as v(tbl, oldname)
  loop
    execute format('drop policy if exists %I on %I', rec.oldname, rec.tbl);
    execute format('create policy %I on %I for insert to authenticated with check (tenant_id = current_tenant_id() and is_mas())', rec.tbl||'_ins', rec.tbl);
    execute format('create policy %I on %I for update to authenticated using (tenant_id = current_tenant_id() and is_mas()) with check (tenant_id = current_tenant_id() and is_mas())', rec.tbl||'_upd', rec.tbl);
    execute format('create policy %I on %I for delete to authenticated using (tenant_id = current_tenant_id() and is_mas())', rec.tbl||'_del', rec.tbl);
  end loop;
end $$;

-- -------------------------------------------------------------
-- 10. tenants: 運営は会社一覧を見られる＋入っている会社の設定を変更できる
-- -------------------------------------------------------------
drop policy if exists tenants_sel on tenants;
create policy tenants_sel on tenants for select to authenticated
  using (id = current_tenant_id() or id = current_acting_tenant_id() or is_platform_admin());
-- 会社設定(会社名・アイコン・背景)の変更は、運営が「入っている会社」に対してのみ
create policy tenants_upd on tenants for update to authenticated
  using (id = current_acting_tenant_id() and is_platform_admin())
  with check (id = current_acting_tenant_id() and is_platform_admin());
