-- =============================================================
-- DO'reS STEP3 — 機能の表示（使える/準備中/出さない）＋ 開発と反映
-- 設計: 追加3（開発と反映：段階・バージョン・会社ごとの反映）＋ 追加6（THINKING/DOING/FUTUREの層・仮）。
--
-- 方針:
--  - 機能カタログ features（key・名前・段階・層・今のバージョン・ひとこと）。
--  - 会社ごとの機能の状態 tenant_features（使える/準備中/出さない＋この会社が使えるバージョン）。
--  - 「準備中/出さない」は画面で隠すだけでなく DB側でも遮断（お知らせを例に notices の閲覧に条件追加）。
--  - 反映は tenant_features を更新することで会社ごとに順番に届ける。記録は feature_reflections。
--  - 追加6: 層 feature_layers(THINKING/DOING/FUTURE) は「仮」で、あとで自由に変えられる（表にする）。
--  - 変更(反映・状態切替)は DO'reS運営(platform_admin)だけ。
--  - 適用済みマイグレーションは変更せず、この新しい1本で足す。yellowの機能設定は本番互換のためここで入れる。
-- =============================================================

-- -------------------------------------------------------------
-- 1. 層 feature_layers（追加6・THINKING/DOING/FUTURE。仮＝あとで変えられる表）
-- -------------------------------------------------------------
create table feature_layers (
  layer      text primary key,
  label      text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table feature_layers is '機能のロードマップの層（仮）。THINKING/DOING/FUTURE。あとで自由に増減・改名できる';
create trigger trg_feature_layers_updated before update on feature_layers for each row execute function set_updated_at();

insert into feature_layers (layer, label, sort_order) values
  ('THINKING','構想中（THINKING）',1),
  ('DOING','開発・運用中（DOING）',2),
  ('FUTURE','将来（FUTURE）',3)
on conflict (layer) do nothing;

-- -------------------------------------------------------------
-- 2. 機能カタログ features
--    段階 stage: planning=計画中 / developing=開発中 / testing=テスト中 / done=完成
-- -------------------------------------------------------------
create table features (
  key             text primary key,
  name            text not null,
  description     text,
  stage           text not null default 'planning' check (stage in ('planning','developing','testing','done')),
  layer           text references feature_layers(layer) on delete set null,
  current_version text not null default 'v1.0',
  sort_order      integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
comment on table features is '機能カタログ。段階(計画中〜完成)・層(THINKING/DOING/FUTURE)・今のバージョン・ひとこと';
comment on column features.stage is '段階: planning=計画中 / developing=開発中 / testing=テスト中 / done=完成';
create trigger trg_features_updated before update on features for each row execute function set_updated_at();

-- 本物の機能（お知らせ）。yellowで稼働中。完成・DOING・v1.1。
insert into features (key, name, description, stage, layer, current_version, sort_order) values
  ('notices','お知らせ','全社・店舗・個人へのお知らせと確認','done','DOING','v1.1',1)
on conflict (key) do nothing;

-- -------------------------------------------------------------
-- 3. 会社ごとの機能の状態 tenant_features
--    state: available=使える / preparing=準備中 / hidden=出さない
--    enabled_version: この会社が今使えるバージョン（反映で更新）
-- -------------------------------------------------------------
create table tenant_features (
  tenant_id       uuid not null references tenants(id) on delete restrict,
  feature_key     text not null references features(key) on delete restrict,
  state           text not null default 'preparing' check (state in ('available','preparing','hidden')),
  enabled_version text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  primary key (tenant_id, feature_key)
);
comment on table tenant_features is '会社ごとの機能の状態（使える/準備中/出さない）＋その会社が使えるバージョン';
comment on column tenant_features.state is 'available=使える / preparing=準備中 / hidden=出さない';
create trigger trg_tenant_features_updated before update on tenant_features for each row execute function set_updated_at();

-- yellow はお知らせを「使える」・最新 v1.1（本番互換。これが無いと現行アプリのお知らせが止まるため migration で入れる）
insert into tenant_features (tenant_id, feature_key, state, enabled_version) values
  ('0000ffff-0000-0000-0000-000000000001','notices','available','v1.1')
on conflict (tenant_id, feature_key) do nothing;

-- -------------------------------------------------------------
-- 4. 反映の記録 feature_reflections（会社ごとにどのバージョンを届けたか。元に戻せるよう履歴を残す）
-- -------------------------------------------------------------
create table feature_reflections (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references tenants(id) on delete restrict,
  feature_key  text not null references features(key) on delete restrict,
  from_version text,
  to_version   text,
  reflected_by uuid references people(id) on delete set null,
  note         text,
  at           timestamptz not null default now()
);
comment on table feature_reflections is '機能の反映の記録（会社・機能・前後のバージョン・実施者）。履歴として残し、元に戻すときも1行足す';
create index idx_freflect_tenant on feature_reflections(tenant_id);

-- -------------------------------------------------------------
-- 5. 判定関数（security definer・anon不可）
-- -------------------------------------------------------------
-- その会社でその機能が「使える」か
create or replace function feature_available(p_tenant uuid, p_key text)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from tenant_features tf
    where tf.tenant_id = p_tenant and tf.feature_key = p_key and tf.state = 'available'
  );
$$;

-- その会社でその機能が使える「今のバージョン」
create or replace function feature_enabled_version(p_tenant uuid, p_key text)
returns text language sql stable security definer set search_path = public, pg_temp as $$
  select enabled_version from tenant_features
  where tenant_id = p_tenant and feature_key = p_key;
$$;

revoke execute on function feature_available(uuid,text), feature_enabled_version(uuid,text) from public;
revoke execute on function feature_available(uuid,text), feature_enabled_version(uuid,text) from anon;
grant  execute on function feature_available(uuid,text), feature_enabled_version(uuid,text) to authenticated;

-- -------------------------------------------------------------
-- 6. 新しい表の RLS
-- -------------------------------------------------------------
alter table feature_layers      enable row level security;
alter table features            enable row level security;
alter table tenant_features     enable row level security;
alter table feature_reflections enable row level security;

-- カタログ（層・機能）はログイン者が読める。変更は運営のみ。
create policy feature_layers_sel on feature_layers for select to authenticated using (true);
create policy feature_layers_ins on feature_layers for insert to authenticated with check (is_platform_admin());
create policy feature_layers_upd on feature_layers for update to authenticated using (is_platform_admin()) with check (is_platform_admin());

create policy features_sel on features for select to authenticated using (true);
create policy features_ins on features for insert to authenticated with check (is_platform_admin());
create policy features_upd on features for update to authenticated using (is_platform_admin()) with check (is_platform_admin());

-- 会社ごとの状態は、その会社(自社/入っている会社) or 運営が見える。変更(反映・切替)は運営のみ。
create policy tenant_features_sel on tenant_features for select to authenticated
  using (tenant_id = current_tenant_id() or tenant_id = current_acting_tenant_id() or is_platform_admin());
create policy tenant_features_ins on tenant_features for insert to authenticated with check (is_platform_admin());
create policy tenant_features_upd on tenant_features for update to authenticated using (is_platform_admin()) with check (is_platform_admin());

-- 反映の記録は、運営 or その会社のMAS が見える。作成は運営のみ。
create policy freflect_sel on feature_reflections for select to authenticated
  using (is_platform_admin() or (is_mas() and current_tenant_id() = tenant_id));
create policy freflect_ins on feature_reflections for insert to authenticated with check (is_platform_admin());

-- -------------------------------------------------------------
-- 7. お知らせの閲覧に「この会社でお知らせが使えるなら」を追加（DBで遮断）
--    準備中/出さない の会社では、URL直打ちでも notices は0件。
-- -------------------------------------------------------------
drop policy if exists notices_sel on notices;
create policy notices_sel on notices for select to authenticated
  using (
    tenant_id = current_acting_tenant_id()
    and feature_available(current_acting_tenant_id(), 'notices')
    and (is_acting_cross_tenant() or is_mas() or (status = 'published' and notice_is_target(id)))
  );
