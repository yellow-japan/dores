-- =============================================================
-- DO'reS STEP1(お知らせ) — 設定・お知らせの表・権限(RLS)・Storage
--
-- 方針（指示書＋追加4点）:
--  - 新しい表は最初から RLS 有効。判定関数は security definer + search_path 固定。
--  - 追加1: エリア宛ては「その下の階層のエリアの店舗」も対象に含める（area階層を上にたどる）。
--  - 追加2: app_settings は1行だけ（2行目を作れない仕組み）。
--  - 追加3: 新しい表は MAS でも行削除不可（DELETEポリシーを作らない。終了は状態で表す）。
--  - 追加4: 新しい判定関数は anon（未ログイン）から呼べない（public/anonのEXECUTEを剥奪）。
--
-- 順序: 表 → 判定関数 → RLS/ポリシー → Storage
-- =============================================================

-- -------------------------------------------------------------
-- 設定 app_settings（1行だけ・追加2）
-- -------------------------------------------------------------
create table app_settings (
  id                     integer primary key default 1,
  company_display_name   text not null default 'yellow.inc',
  background_image_path  text,                 -- Supabase Storage のパス。空ならアプリ側で同梱の初期画像を使う
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  constraint app_settings_single_row check (id = 1)   -- id は常に1 → PKと合わせて2行目を作れない
);
comment on table app_settings is '全体設定（会社表示名・背景画像）。常に1行だけ（id=1固定）';
comment on column app_settings.background_image_path is 'Storage(brandingバケット)内のパス。空ならアプリが同梱の初期画像を使う';

-- -------------------------------------------------------------
-- お知らせ本体 notices
-- -------------------------------------------------------------
create table notices (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  body         text not null,
  is_important boolean not null default false,
  status       text not null default 'draft' check (status in ('draft','published','closed')),
  published_at timestamptz,
  created_by   uuid references people(id) on delete restrict,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
comment on table notices is 'お知らせ本体。status: draft=下書き / published=公開 / closed=終了（削除はしない）';

-- お知らせの対象（組み合わせ可・削除せず active で状態管理）
create table notice_targets (
  id          uuid primary key default gen_random_uuid(),
  notice_id   uuid not null references notices(id) on delete restrict,
  target_type text not null check (target_type in ('all','rank','store','area','person')),
  target_id   uuid,
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint notice_targets_id_check check (
    (target_type = 'all' and target_id is null) or
    (target_type <> 'all' and target_id is not null)
  )
);
comment on table notice_targets is 'お知らせの対象。全員/ランク/店舗/エリア/個人を複数組み合わせ可。対象の取消は active=false（行は消さない）';

-- 確認（「確認しました」）。1人1回・取消不可・他人不可
create table notice_acks (
  id         uuid primary key default gen_random_uuid(),
  notice_id  uuid not null references notices(id) on delete restrict,
  person_id  uuid not null references people(id) on delete restrict,
  acked_at   timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (notice_id, person_id)
);
comment on table notice_acks is 'お知らせ確認。1人1回（unique）。取消・他人分は不可（DELETE/UPDATEポリシーを作らない）';

-- 索引
create index idx_notice_targets_notice on notice_targets(notice_id);
create index idx_notice_targets_type   on notice_targets(target_type, target_id);
create index idx_notice_acks_notice    on notice_acks(notice_id);
create index idx_notice_acks_person    on notice_acks(person_id);
create index idx_notices_status        on notices(status);

-- updated_at トリガ（既存の set_updated_at を利用）
create trigger trg_app_settings_updated  before update on app_settings  for each row execute function set_updated_at();
create trigger trg_notices_updated        before update on notices        for each row execute function set_updated_at();
create trigger trg_notice_targets_updated before update on notice_targets for each row execute function set_updated_at();
create trigger trg_notice_acks_updated    before update on notice_acks    for each row execute function set_updated_at();

-- -------------------------------------------------------------
-- 判定用の関数（表の後に定義。security definer・search_path固定・anon不可）
-- -------------------------------------------------------------

-- 現在のランク（rank_history の最新）
create or replace function current_rank_id()
returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select rank_id from rank_history
  where person_id = current_person_id()
  order by achieved_on desc, created_at desc
  limit 1;
$$;

-- 自分の「現在の所属店舗のエリア」と、その上位エリア全部（階層を上にたどる）
create or replace function my_area_ids()
returns setof uuid language sql stable security definer set search_path = public, pg_temp as $$
  with recursive anc(area_id) as (
    select s.area_id
      from assignments a
      join stores s on s.id = a.store_id
     where a.person_id = current_person_id() and a.store_id is not null
       and a.start_on <= current_date and a.end_on is null
       and s.area_id is not null
    union
    select ar.parent_area_id
      from anc join areas ar on ar.id = anc.area_id
     where ar.parent_area_id is not null
  )
  select distinct area_id from anc;
$$;

-- 自分が、そのお知らせの対象に入っているか（対象の組み合わせを満たすか）
create or replace function notice_is_target(p_notice uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from notice_targets t
    where t.notice_id = p_notice and t.active
      and (
        t.target_type = 'all'
        or (t.target_type = 'person' and t.target_id = current_person_id())
        or (t.target_type = 'rank'   and t.target_id = current_rank_id())
        or (t.target_type = 'store'  and t.target_id in (
              select a.store_id from assignments a
              where a.person_id = current_person_id() and a.store_id is not null
                and a.start_on <= current_date and a.end_on is null))
        or (t.target_type = 'area'   and t.target_id in (select my_area_ids()))
      )
  );
$$;

-- anon(未ログイン)・public から呼べないようにする（追加4）。authenticated だけ許可。
revoke execute on function current_rank_id(), my_area_ids(), notice_is_target(uuid) from public;
grant  execute on function current_rank_id(), my_area_ids(), notice_is_target(uuid) to authenticated;

-- -------------------------------------------------------------
-- RLS 有効化（最初から）
-- -------------------------------------------------------------
alter table app_settings   enable row level security;
alter table notices        enable row level security;
alter table notice_targets enable row level security;
alter table notice_acks    enable row level security;

-- app_settings: 読み取りはログイン者全員、作成/更新は MAS。削除ポリシーは作らない。
create policy app_settings_sel on app_settings for select to authenticated using (true);
create policy app_settings_ins on app_settings for insert to authenticated with check (is_mas());
create policy app_settings_upd on app_settings for update to authenticated using (is_mas()) with check (is_mas());

-- notices: 閲覧は「MAS（下書き含む全部）」or「公開中かつ自分が対象」。作成/更新は MAS。削除ポリシーなし。
create policy notices_sel on notices for select to authenticated
  using ( is_mas() or (status = 'published' and notice_is_target(id)) );
create policy notices_ins on notices for insert to authenticated with check (is_mas());
create policy notices_upd on notices for update to authenticated using (is_mas()) with check (is_mas());

-- notice_targets: 閲覧/作成/更新は MAS のみ（対象情報は本部管理）。削除ポリシーなし。
create policy notice_targets_sel on notice_targets for select to authenticated using (is_mas());
create policy notice_targets_ins on notice_targets for insert to authenticated with check (is_mas());
create policy notice_targets_upd on notice_targets for update to authenticated using (is_mas()) with check (is_mas());

-- notice_acks:
--   閲覧: MAS=全部 / 本人=自分 / 管理職= can_see_person で見てよい人の分
--   作成: 本人の分だけ、かつ「自分に見えている公開中のお知らせ」だけ
--   更新/削除ポリシーは作らない（取消不可・他人不可）
create policy notice_acks_sel on notice_acks for select to authenticated
  using ( is_mas() or person_id = current_person_id() or can_see_person(person_id) );
create policy notice_acks_ins on notice_acks for insert to authenticated
  with check (
    person_id = current_person_id()
    and exists (
      select 1 from notices n
      where n.id = notice_id and n.status = 'published' and notice_is_target(n.id)
    )
  );

-- -------------------------------------------------------------
-- Storage: 背景画像のバケット（非公開）＋権限
-- -------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('branding', 'branding', false)
on conflict (id) do nothing;

-- 閲覧（ダウンロード）はログイン者、アップロード/差し替えは MAS。削除ポリシーは作らない。
create policy branding_read   on storage.objects for select to authenticated using (bucket_id = 'branding');
create policy branding_insert on storage.objects for insert to authenticated with check (bucket_id = 'branding' and is_mas());
create policy branding_update on storage.objects for update to authenticated using (bucket_id = 'branding' and is_mas()) with check (bucket_id = 'branding' and is_mas());
