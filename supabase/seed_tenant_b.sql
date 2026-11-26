-- =============================================================
-- DO'reS テストデータ: もう1つの会社「テスト株式会社B」（すべて架空）
--   会社ごとの分離(テナント)を確認するための2社目。
--   既存の seed.sql / seed_notices.sql（yellowテナント）を読み込んだ後に実行する。
--   本物の個人情報・店舗データは入れない。メールは example.invalid。
--   tenant_id は毎回はっきり指定する（既定値に頼らない）。
-- =============================================================

-- ---- テナント（会社）B ----
insert into tenants (id, slug, display_name, status) values
  ('0000ffff-0000-0000-0000-000000000002','test-b','テスト株式会社B','preparing')
on conflict (id) do nothing;

-- ---- 認証ユーザー（パスワード空＝実ログイン不可。テストはJWT擬似） ----
insert into auth.users
  (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
   created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
   confirmation_token, email_change, email_change_token_new, recovery_token)
values
  ('00000000-0000-0000-0000-000000000000','0000bbbb-0000-0000-0000-000000000001','authenticated','authenticated','test-b-mas@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','',''),
  ('00000000-0000-0000-0000-000000000000','0000bbbb-0000-0000-0000-000000000002','authenticated','authenticated','test-b-tencho@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','',''),
  ('00000000-0000-0000-0000-000000000000','0000bbbb-0000-0000-0000-000000000003','authenticated','authenticated','test-b-part@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','','')
on conflict (id) do nothing;

-- ---- 法人・業態・エリア・部署 ----
insert into companies (id, tenant_id, name, company_type) values
  ('0000bbbb-0000-0000-0000-0000000000c1','0000ffff-0000-0000-0000-000000000002','テストB自社','own')
on conflict (id) do nothing;

insert into brands (id, tenant_id, name, status) values
  ('0000bbbb-0000-0000-0000-0000000000b1','0000ffff-0000-0000-0000-000000000002','テストB業態','active')
on conflict (id) do nothing;

insert into areas (id, tenant_id, name) values
  ('0000bbbb-0000-0000-0000-0000000000e1','0000ffff-0000-0000-0000-000000000002','テストB中央エリア')
on conflict (id) do nothing;

insert into departments (id, tenant_id, name) values
  ('0000bbbb-0000-0000-0000-0000000000d1','0000ffff-0000-0000-0000-000000000002','テストB本部')
on conflict (id) do nothing;

-- ---- 店舗（2店。store_code は yellow と同じ T001 を使い「会社の中で一意」を確認） ----
insert into stores (id, tenant_id, store_code, name, brand_id, area_id, company_id, operation_type, status, opened_on) values
  ('0000bbbb-0000-0000-0000-000000000051','0000ffff-0000-0000-0000-000000000002','T001','テストB店舗1','0000bbbb-0000-0000-0000-0000000000b1','0000bbbb-0000-0000-0000-0000000000e1','0000bbbb-0000-0000-0000-0000000000c1','direct','open', current_date - 120),
  ('0000bbbb-0000-0000-0000-000000000052','0000ffff-0000-0000-0000-000000000002','T002','テストB店舗2','0000bbbb-0000-0000-0000-0000000000b1','0000bbbb-0000-0000-0000-0000000000e1','0000bbbb-0000-0000-0000-0000000000c1','direct','open', current_date - 90)
on conflict (id) do nothing;

-- ---- ランク ----
insert into ranks (id, tenant_id, name, sort_order) values
  ('0000bbbb-0000-0000-0000-000000000011','0000ffff-0000-0000-0000-000000000002','テストBランク1',1)
on conflict (id) do nothing;

-- ---- 人（社員番号は yellow と同じ E001 等。会社の中で一意） ----
insert into people (id, tenant_id, employee_code, display_name, employment_status, joined_on, auth_user_id) values
  ('0000bbbb-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002','E001','テストB管理者','active', current_date - 120,'0000bbbb-0000-0000-0000-000000000001'),
  ('0000bbbb-0000-0000-0000-000000000002','0000ffff-0000-0000-0000-000000000002','E002','テストB店長', 'active', current_date - 110,'0000bbbb-0000-0000-0000-000000000002'),
  ('0000bbbb-0000-0000-0000-000000000003','0000ffff-0000-0000-0000-000000000002','E003','テストBアルバイト','active', current_date - 80,'0000bbbb-0000-0000-0000-000000000003')
on conflict (id) do nothing;

insert into employment_history (id, tenant_id, person_id, kind, start_on, end_on) values
  ('0000bbbb-0000-0000-0000-0000000000f1','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000001','employee', current_date - 120, null),
  ('0000bbbb-0000-0000-0000-0000000000f2','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000002','employee', current_date - 110, null),
  ('0000bbbb-0000-0000-0000-0000000000f3','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000003','part_time', current_date - 80, null)
on conflict (id) do nothing;

insert into people_private (person_id, tenant_id, legal_name, contact, birth_date, monthly_salary, hourly_wage) values
  ('0000bbbb-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002','架空 B管理者','test-b-mas@example.invalid','1986-01-01', 550000, null),
  ('0000bbbb-0000-0000-0000-000000000002','0000ffff-0000-0000-0000-000000000002','架空 B店長','test-b-tencho@example.invalid','1992-02-02', 330000, null),
  ('0000bbbb-0000-0000-0000-000000000003','0000ffff-0000-0000-0000-000000000002','架空 Bアルバイト','test-b-part@example.invalid','2002-03-03', null, 1300)
on conflict (person_id) do nothing;

-- ---- 所属 ----
insert into assignments (id, tenant_id, person_id, store_id, department_id, position, assignment_type, start_on) values
  ('0000bbbb-0000-0000-0000-0000000000a1','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000001', null,'0000bbbb-0000-0000-0000-0000000000d1','本部','primary', current_date - 120),
  ('0000bbbb-0000-0000-0000-0000000000a2','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000051', null,'店長','primary', current_date - 110),
  ('0000bbbb-0000-0000-0000-0000000000a3','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000003','0000bbbb-0000-0000-0000-000000000051', null,'一般','primary', current_date - 80)
on conflict (id) do nothing;

-- ---- 権限 ----
insert into role_grants (id, tenant_id, person_id, role, scope, scope_id, start_on, end_on) values
  ('0000bbbb-0000-0000-0000-0000000000aa','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000001','MAS','all',     null,                                   current_date - 120, null),
  ('0000bbbb-0000-0000-0000-0000000000ab','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000002','LEA','store',   '0000bbbb-0000-0000-0000-000000000051', current_date - 110, null),
  ('0000bbbb-0000-0000-0000-0000000000ac','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000003','PART','store',  '0000bbbb-0000-0000-0000-000000000051', current_date - 80,  null)
on conflict (id) do nothing;

-- ---- お知らせ（全員向け1・下書き1） ----
insert into notices (id, tenant_id, title, body, is_important, status, published_at, created_by) values
  ('0000bbbb-0000-0000-0000-000000000071','0000ffff-0000-0000-0000-000000000002','テストB：全社お知らせ','B社の全員向け。', true, 'published', now(), '0000bbbb-0000-0000-0000-000000000001'),
  ('0000bbbb-0000-0000-0000-000000000072','0000ffff-0000-0000-0000-000000000002','テストB：下書き','B社の下書き。', false,'draft', null, '0000bbbb-0000-0000-0000-000000000001')
on conflict (id) do nothing;

insert into notice_targets (id, tenant_id, notice_id, target_type, target_id) values
  ('0000bbbb-0000-0000-0000-000000000081','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000071','all', null),
  ('0000bbbb-0000-0000-0000-000000000082','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000072','all', null)
on conflict (id) do nothing;

insert into notice_acks (id, tenant_id, notice_id, person_id) values
  ('0000bbbb-0000-0000-0000-000000000091','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000071','0000bbbb-0000-0000-0000-000000000002')
on conflict (id) do nothing;
