-- =============================================================
-- DO'reS STEP5 — URL↔テナントの対応をデータ化（追加7）＋ 運営がWebで会社に入って見られるように
--
-- 1. tenant_hostnames：どのURL(ホスト名)がどの会社か/DO'reS運営かを「データ」で持つ。
--    プログラムに直接書かない。登録のないURLは入口を出さない（ログインさせない）。
-- 2. current_acting_tenant_id()：Webでは request.acting_tenant を渡せないので、
--    「開いている入室記録（exited_at空・8時間以内・有効な許可）」から今の会社を決める方式に変更。
--    → 運営が「入る」で入室記録を作れば、その間はその会社として中を見られる（帯つき）。
-- 3. 補助関数：my_person()（acting中でも自分の名前を取れる）、host_branding()（未ログインでも
--    そのURLの会社名・背景を1件だけ返す＝一覧は晒さない）。
--
-- ※ 適用済みマイグレーションは変更せず、この新しい1本で足す。
-- =============================================================

-- -------------------------------------------------------------
-- 1. URL↔テナントの対応 tenant_hostnames
-- -------------------------------------------------------------
create table tenant_hostnames (
  hostname   text primary key,
  kind       text not null check (kind in ('platform','tenant')),
  tenant_id  uuid references tenants(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint tenant_hostnames_kind_tenant check (
    (kind = 'platform' and tenant_id is null) or
    (kind = 'tenant'   and tenant_id is not null)
  )
);
comment on table tenant_hostnames is 'URL(ホスト名)→DO''reS運営 or 会社(テナント) の対応。プログラムに書かずデータで持つ（追加7）';

-- 登録（代表がVercelに付けた3つ＋開発用localhost）
insert into tenant_hostnames (hostname, kind, tenant_id) values
  ('dores-home.vercel.app',  'platform', null),
  ('yellow-dores.vercel.app','tenant',  '0000ffff-0000-0000-0000-000000000001'),
  ('dores-ruby.vercel.app',  'tenant',  '0000ffff-0000-0000-0000-000000000001'),
  ('localhost:3000',         'tenant',  '0000ffff-0000-0000-0000-000000000001'),
  ('localhost',              'tenant',  '0000ffff-0000-0000-0000-000000000001')
on conflict (hostname) do nothing;

-- 対応表は未ログインでも読めてよい（会社名の表示判定に使う）。書き込みは運営・マイグレーションで。
alter table tenant_hostnames enable row level security;
create policy tenant_hostnames_sel_anon on tenant_hostnames for select to anon using (true);
create policy tenant_hostnames_sel_auth on tenant_hostnames for select to authenticated using (true);

-- -------------------------------------------------------------
-- 2. current_acting_tenant_id()：開いている入室記録から今の会社を決める（GUC不要）
--    条件：本人の company_access_sessions で exited_at空・entered_at が8時間以内・今も入れる許可。
--    無ければ必ず自分の所属会社。
-- -------------------------------------------------------------
create or replace function current_acting_tenant_id()
returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce(
    (
      select s.target_tenant_id
      from company_access_sessions s
      where s.person_id = current_person_id()
        and s.exited_at is null
        and s.entered_at >= now() - interval '8 hours'
        and can_enter_tenant(s.target_tenant_id)
      order by s.entered_at desc
      limit 1
    ),
    current_tenant_id()
  );
$$;
comment on function current_acting_tenant_id() is
  '今どの会社として動いているか。開いている入室記録(8時間以内)＋有効な許可があればその会社、無ければ所属会社。';

-- -------------------------------------------------------------
-- 3a. my_person()：ログイン中の本人(id・表示名)。acting が他社でも自分を取れる（RLSを跨ぐ）。
-- -------------------------------------------------------------
create or replace function my_person()
returns table(id uuid, display_name text)
language sql stable security definer set search_path = public, pg_temp as $$
  select p.id, p.display_name from people p where p.auth_user_id = auth.uid();
$$;
revoke execute on function my_person() from public;
revoke execute on function my_person() from anon;
grant  execute on function my_person() to authenticated;

-- -------------------------------------------------------------
-- 3b. host_branding()：そのURL(ホスト名)の種別と会社名・背景を「1件だけ」返す。
--     未ログイン(anon)でも呼べる。会社一覧は晒さない（該当ホストの1件のみ）。
--     未登録ホストは0件（＝入口を出さない）。
-- -------------------------------------------------------------
create or replace function host_branding(p_host text)
returns table(kind text, tenant_id uuid, slug text, display_name text, background_image_path text)
language sql stable security definer set search_path = public, pg_temp as $$
  select th.kind, th.tenant_id, t.slug, t.display_name, t.background_image_path
  from tenant_hostnames th
  left join tenants t on t.id = th.tenant_id
  where th.hostname = lower(p_host);
$$;
grant execute on function host_branding(text) to anon;
grant execute on function host_branding(text) to authenticated;
