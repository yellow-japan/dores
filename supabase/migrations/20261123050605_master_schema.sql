-- =============================================================
-- DO'reS 共通マスター スキーマ（STEP2）
-- 設計の正本: yellow-brain/06_system/master-data-design.md (status: approved)
--
-- 原則:
--  - ID は自動採番 (uuid)。人が読むコード（店舗コード・社員番号）は別列
--  - すべての表に created_at / updated_at（updated_at は自動更新）
--  - 削除しない設計：状態の列で表す。外部キーは on delete restrict
--  - 区分・状態は CHECK 制約で値を限定
--  - 「今の所属」「今の権限」は終了日が空のものをビューで取得
--
-- 本マイグレーションの範囲: 表・制約・索引・updated_atトリガ・current_*ビュー。
-- RLS（行レベル権限）・判定関数・テストデータは STEP3 で別途作成する。
-- =============================================================

create extension if not exists pgcrypto;

-- updated_at を自動更新する共通トリガ関数
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -------------------------------------------------------------
-- 1. 法人 companies
-- -------------------------------------------------------------
create table companies (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  company_type text not null check (company_type in ('own','group','fc_partner')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
comment on table  companies is '法人';
comment on column companies.company_type is '区分: own=自社 / group=グループ会社 / fc_partner=FC加盟法人';

-- -------------------------------------------------------------
-- 2. 業態（ブランド） brands
-- -------------------------------------------------------------
create table brands (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  status     text not null default 'active' check (status in ('active','developing','closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table  brands is '業態（ブランド）';
comment on column brands.status is '状態: active=運営中 / developing=開発中 / closed=終了';

-- -------------------------------------------------------------
-- 3. エリア areas（上位エリアで階層化）
-- -------------------------------------------------------------
create table areas (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  parent_area_id uuid references areas(id) on delete restrict,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
comment on table  areas is 'エリア';
comment on column areas.parent_area_id is '上位エリア（国→地方→エリア のように階層化。最上位は null）';

-- -------------------------------------------------------------
-- 4. 部署 departments
-- -------------------------------------------------------------
create table departments (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table departments is '部署（店舗に属さない所属先）';

-- -------------------------------------------------------------
-- 5. ランク ranks（段階は後から自由に増減できる形）
-- -------------------------------------------------------------
create table ranks (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table  ranks is 'ランク（教育制度で確定。並び順で段階を表す）';
comment on column ranks.sort_order is '並び順（小さいほど下位。段階の増減に対応）';

-- -------------------------------------------------------------
-- 6. 店舗 stores
-- -------------------------------------------------------------
create table stores (
  id             uuid primary key default gen_random_uuid(),
  store_code     text not null unique,
  name           text not null,
  brand_id       uuid not null references brands(id)    on delete restrict,
  area_id        uuid          references areas(id)     on delete restrict,
  company_id     uuid not null references companies(id) on delete restrict,
  operation_type text not null check (operation_type in ('direct','fc')),
  status         text not null default 'open' check (status in ('preparing','open','suspended','closed')),
  opened_on      date,
  closed_on      date,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
comment on table  stores is '店舗';
comment on column stores.store_code     is '人が読む店舗コード（例 Y001）';
comment on column stores.area_id        is 'エリア（任意）';
comment on column stores.company_id     is '運営法人（直営=自社 / FC=加盟法人）';
comment on column stores.operation_type is '運営形態: direct=直営 / fc=FC';
comment on column stores.status         is '状態: preparing=開店準備中 / open=営業中 / suspended=休業中 / closed=閉店';

-- -------------------------------------------------------------
-- 7. 店舗の外部連携ID store_external_ids
--    （現行の「店舗名マッピング」を置き換え）
-- -------------------------------------------------------------
create table store_external_ids (
  id          uuid primary key default gen_random_uuid(),
  store_id    uuid not null references stores(id) on delete restrict,
  provider    text not null check (provider in ('dinii','google_place','instagram','other')),
  external_id text not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (store_id, provider)
);
comment on table  store_external_ids is '店舗の外部連携ID（ダイニー店舗名 / Google Place ID / InstagramアカウントID など）';
comment on column store_external_ids.provider is '連携先: dinii / google_place / instagram / other';

-- -------------------------------------------------------------
-- 8. 人 people（社員・アルバイト・FCスタッフを同じ「人」で管理）
-- -------------------------------------------------------------
create table people (
  id                uuid primary key default gen_random_uuid(),
  employee_code     text not null unique,
  display_name      text not null,
  employment_status text not null default 'active' check (employment_status in ('active','leave','resigned')),
  joined_on         date,
  left_on           date,
  resignation_type  text check (resignation_type in ('graduation','unavoidable','values_gap','involuntary')),
  auth_user_id      uuid unique references auth.users(id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
comment on table  people is '人（社員・アルバイト・FCスタッフ共通。雇用区分は employment_history で履歴管理）';
comment on column people.employee_code     is '人が読む社員番号';
comment on column people.display_name      is '表示名・ニックネーム';
comment on column people.employment_status is '在籍状態: active=在籍 / leave=休職 / resigned=退職';
comment on column people.resignation_type  is '退職分類: graduation=卒業 / unavoidable=やむなし / values_gap=価値観相違 / involuntary=非自発';
comment on column people.auth_user_id      is 'ログインアカウント（Supabase Auth のユーザーID。削除時は null に）';

-- -------------------------------------------------------------
-- 9. 雇用区分の履歴 employment_history
-- -------------------------------------------------------------
create table employment_history (
  id         uuid primary key default gen_random_uuid(),
  person_id  uuid not null references people(id) on delete restrict,
  kind       text not null check (kind in ('employee','part_time','contractor','fc_staff')),
  start_on   date not null,
  end_on     date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table  employment_history is '雇用区分の履歴（アルバイト→社員 などの変化を1本の人としてつなぐ）';
comment on column employment_history.kind   is '雇用区分: employee=社員 / part_time=アルバイト / contractor=業務委託 / fc_staff=FCスタッフ';
comment on column employment_history.end_on is '終了日。空＝現在の雇用区分';

-- -------------------------------------------------------------
-- 10. 個人情報 people_private（1対1・厳しい権限はSTEP3のRLSで）
-- -------------------------------------------------------------
create table people_private (
  person_id      uuid primary key references people(id) on delete restrict,
  legal_name     text,
  contact        text,
  birth_date     date,
  monthly_salary numeric(12,2),
  hourly_wage    numeric(10,2),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
comment on table people_private is '個人情報（本名・連絡先・生年月日・給与/時給）。本人とMASだけが見られる（RLSはSTEP3）';

-- -------------------------------------------------------------
-- 11. 所属履歴 assignments（店舗 または 部署 のどちらか一方）
-- -------------------------------------------------------------
create table assignments (
  id              uuid primary key default gen_random_uuid(),
  person_id       uuid not null references people(id) on delete restrict,
  store_id        uuid references stores(id)      on delete restrict,
  department_id   uuid references departments(id) on delete restrict,
  position        text,
  assignment_type text not null default 'primary' check (assignment_type in ('primary','concurrent')),
  start_on        date not null,
  end_on          date,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint assignments_target_one check ((store_id is not null)::int + (department_id is not null)::int = 1)
);
comment on table  assignments is '所属履歴（異動・ヘルプ・兼務を表す）';
comment on column assignments.position        is '役職（店長／副店長／一般 など）';
comment on column assignments.assignment_type is 'primary=主所属 / concurrent=兼務';
comment on column assignments.end_on          is '終了日。空＝現在の所属';
comment on constraint assignments_target_one on assignments is '所属先は店舗か部署のどちらか一方（両方・両方空は不可）';

-- -------------------------------------------------------------
-- 12. 権限 role_grants（役割 × 範囲）
-- -------------------------------------------------------------
create table role_grants (
  id         uuid primary key default gen_random_uuid(),
  person_id  uuid not null references people(id) on delete restrict,
  role       text not null check (role  in ('MAS','AREA','LEA','MEM','PART','FC')),
  scope      text not null check (scope in ('all','area','store','department','company')),
  scope_id   uuid,
  start_on   date not null,
  end_on     date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((scope = 'all' and scope_id is null) or (scope <> 'all' and scope_id is not null))
);
comment on table  role_grants is '権限（役割×範囲）。期限付きで付与し、異動で切り替える';
comment on column role_grants.role     is '役割: MAS=本部管理者 / AREA=エリア長 / LEA=店長 / MEM=社員 / PART=アルバイト / FC=FCオーナー';
comment on column role_grants.scope    is '範囲: all=全社 / area=エリア / store=店舗 / department=部署 / company=法人';
comment on column role_grants.scope_id is '範囲のID（area/store/department/company のID。scope=all のときは null。多態のためFKは張らない）';

-- -------------------------------------------------------------
-- 13. ランク履歴 rank_history
-- -------------------------------------------------------------
create table rank_history (
  id          uuid primary key default gen_random_uuid(),
  person_id   uuid not null references people(id) on delete restrict,
  rank_id     uuid not null references ranks(id)  on delete restrict,
  achieved_on date not null,
  basis       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
comment on table  rank_history is 'ランク履歴';
comment on column rank_history.basis is '根拠（後でクエスト・試験の結果IDとつなぐ）';

-- -------------------------------------------------------------
-- 索引（外部キー・絞り込み用）
-- -------------------------------------------------------------
create index idx_areas_parent             on areas(parent_area_id);
create index idx_stores_brand             on stores(brand_id);
create index idx_stores_area              on stores(area_id);
create index idx_stores_company           on stores(company_id);
create index idx_store_ext_store          on store_external_ids(store_id);
create index idx_people_auth_user         on people(auth_user_id);
create index idx_employment_person        on employment_history(person_id);
create index idx_assignments_person       on assignments(person_id);
create index idx_assignments_store        on assignments(store_id);
create index idx_assignments_department   on assignments(department_id);
create index idx_role_grants_person       on role_grants(person_id);
create index idx_role_grants_scope        on role_grants(scope, scope_id);
create index idx_rank_history_person      on rank_history(person_id);
create index idx_rank_history_rank        on rank_history(rank_id);

-- -------------------------------------------------------------
-- updated_at 自動更新トリガ（全表）
-- -------------------------------------------------------------
create trigger trg_companies_updated          before update on companies          for each row execute function set_updated_at();
create trigger trg_brands_updated             before update on brands             for each row execute function set_updated_at();
create trigger trg_areas_updated              before update on areas              for each row execute function set_updated_at();
create trigger trg_departments_updated        before update on departments        for each row execute function set_updated_at();
create trigger trg_ranks_updated              before update on ranks              for each row execute function set_updated_at();
create trigger trg_stores_updated             before update on stores             for each row execute function set_updated_at();
create trigger trg_store_external_ids_updated before update on store_external_ids for each row execute function set_updated_at();
create trigger trg_people_updated             before update on people             for each row execute function set_updated_at();
create trigger trg_employment_history_updated before update on employment_history for each row execute function set_updated_at();
create trigger trg_people_private_updated     before update on people_private     for each row execute function set_updated_at();
create trigger trg_assignments_updated        before update on assignments        for each row execute function set_updated_at();
create trigger trg_role_grants_updated        before update on role_grants        for each row execute function set_updated_at();
create trigger trg_rank_history_updated       before update on rank_history       for each row execute function set_updated_at();

-- -------------------------------------------------------------
-- 「今」を取り出すビュー（終了日が空＝現在）
-- security_invoker=on：STEP3でRLSを有効にしたとき、閲覧者の権限で絞られるようにする
-- -------------------------------------------------------------
create view current_assignments with (security_invoker = on) as
  select * from assignments where end_on is null;
comment on view current_assignments is '現在の所属（end_on が空）';

create view current_role_grants with (security_invoker = on) as
  select * from role_grants where end_on is null;
comment on view current_role_grants is '現在の権限（end_on が空）';
