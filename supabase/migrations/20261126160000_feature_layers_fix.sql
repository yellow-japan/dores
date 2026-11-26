-- =============================================================
-- DO'reS STEP3 追加修正（代表レビュー4点）
-- 正本: yellow-brain 08_ideas/dores-system-concept.md「機能の分類案（仮）」
--
-- 1. 層(feature_layers)は「開発の進み具合」ではなく機能の“分類”。表示名・説明を直す。
--    THINKING=考える・学ぶ / DOING=行動する / FUTURE=未来をつくる。進み具合は features.stage。
-- 2. 「土台」の層を足し、「どの会社にも必ず入る層」の印(required)を層の表に持たせる。
-- 3. 層ごとにまとめて導入する操作（例:ある会社のDOINGを全部「使える」に）を用意。運営だけ・記録に残す。
-- 4. 層の追加・改名・機能の層の付け替えも記録に残す。
--
-- ※ 適用済みマイグレーションは変更せず、この新しい1本で直す。
-- =============================================================

-- -------------------------------------------------------------
-- 1 & 2. feature_layers に説明・必須印を追加し、分類として整える
-- -------------------------------------------------------------
alter table feature_layers add column if not exists description text;
alter table feature_layers add column if not exists required boolean not null default false;
comment on column feature_layers.required is 'どの会社にも必ず入る層（土台）の印。trueは常に必要';

-- 層は「分類」。開発の進み具合(stage)とは別。
update feature_layers set label='考える・学ぶ（THINKING）', description='考え方をそろえる・知る・学ぶ', sort_order=1 where layer='THINKING';
update feature_layers set label='行動する（DOING）',      description='毎日の現場の行動',          sort_order=2 where layer='DOING';
update feature_layers set label='未来をつくる（FUTURE）',  description='数字で振り返り、次を決める',  sort_order=3 where layer='FUTURE';

-- 土台（どの会社にも必ず入る共通部分：ログイン・名簿・権限・設定・運営の入口）
insert into feature_layers (layer, label, description, sort_order, required) values
  ('FOUNDATION','土台（共通）','どの会社にも必ず入る共通部分（ログイン・名簿・権限・設定・DO''reS運営の入口）', 0, true)
on conflict (layer) do update set
  label=excluded.label, description=excluded.description, sort_order=excluded.sort_order, required=excluded.required;

-- -------------------------------------------------------------
-- お知らせは分類上「THINKING（考える・学ぶ）」。STEP3で DOING にしていたのを直す。
-- 見本のシフトは分類上「DOING（行動する）」に揃える（既存dev互換のため、ここで直す）。
-- （層の付け替え記録トリガを作る“前”に直すので、これらの修正自体はログに残さない）
-- -------------------------------------------------------------
update features set layer='THINKING' where key='notices';
update features set layer='DOING'    where key='shifts';   -- 見本機能（無ければ0件）

-- -------------------------------------------------------------
-- 4. 運営の操作を残す記録表 feature_admin_log（層の追加・改名・付け替え・一括導入）
-- -------------------------------------------------------------
create table feature_admin_log (
  id          uuid primary key default gen_random_uuid(),
  action      text not null,              -- layer_add / layer_rename / layer_update / feature_layer_change / layer_apply
  tenant_id   uuid references tenants(id) on delete set null,
  layer       text,
  feature_key text,
  detail      text,
  changed_by  uuid references people(id) on delete set null,
  at          timestamptz not null default now()
);
comment on table feature_admin_log is 'DO''reS運営の機能設定の操作記録（層の追加・改名・付け替え・一括導入）';
create index idx_feature_admin_log_at on feature_admin_log(at);

alter table feature_admin_log enable row level security;
-- 閲覧は運営のみ。書き込みは security definer の関数・トリガ経由だけ（直接insertポリシーは作らない）。
create policy feature_admin_log_sel on feature_admin_log for select to authenticated using (is_platform_admin());

-- -------------------------------------------------------------
-- 3. 層ごとにまとめて導入する操作（運営のみ・記録に残す）
--    例: platform_apply_layer(B社, 'DOING', 'available') で B社の DOING 機能を全部「使える」に。
-- -------------------------------------------------------------
create or replace function platform_apply_layer(p_tenant uuid, p_layer text, p_state text)
returns integer language plpgsql security definer set search_path = public, pg_temp as $$
declare cnt int;
begin
  if not is_platform_admin() then
    raise exception 'この操作はDO''reS運営のみ実行できます';
  end if;
  if p_state not in ('available','preparing','hidden') then
    raise exception '状態が不正です（available/preparing/hidden）';
  end if;

  with upd as (
    insert into tenant_features (tenant_id, feature_key, state)
    select p_tenant, f.key, p_state
    from features f
    where f.layer = p_layer
    on conflict (tenant_id, feature_key) do update set state = excluded.state
    returning 1
  )
  select count(*) into cnt from upd;

  insert into feature_admin_log(action, tenant_id, layer, detail, changed_by)
    values ('layer_apply', p_tenant, p_layer, 'state='||p_state||' / '||cnt||'件', current_person_id());

  return cnt;
end $$;

revoke execute on function platform_apply_layer(uuid,text,text) from public;
revoke execute on function platform_apply_layer(uuid,text,text) from anon;
grant  execute on function platform_apply_layer(uuid,text,text) to authenticated;

-- -------------------------------------------------------------
-- 4. 記録トリガ: 層の追加・改名、機能の層の付け替え
--    （security definer で、変更した本人 current_person_id() を記録）
-- -------------------------------------------------------------
create or replace function log_feature_layer_change()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if tg_op = 'INSERT' then
    insert into feature_admin_log(action, layer, detail, changed_by)
      values ('layer_add', new.layer, 'label='||coalesce(new.label,''), current_person_id());
  elsif tg_op = 'UPDATE' then
    insert into feature_admin_log(action, layer, detail, changed_by)
      values (case when new.label is distinct from old.label then 'layer_rename' else 'layer_update' end,
              new.layer, coalesce(old.label,'')||' -> '||coalesce(new.label,''), current_person_id());
  end if;
  return new;
end $$;
create trigger trg_feature_layers_log after insert or update on feature_layers
  for each row execute function log_feature_layer_change();

create or replace function log_feature_reassign()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.layer is distinct from old.layer then
    insert into feature_admin_log(action, feature_key, layer, detail, changed_by)
      values ('feature_layer_change', new.key, new.layer,
              coalesce(old.layer,'(なし)')||' -> '||coalesce(new.layer,'(なし)'), current_person_id());
  end if;
  return new;
end $$;
create trigger trg_features_layer_log after update of layer on features
  for each row execute function log_feature_reassign();
