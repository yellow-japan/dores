-- =============================================================
-- DO'reS テストデータ（すべて架空）
--   権限(RLS)の動作確認用。本物の個人情報・店舗データは入れない。
--   実行前に RLS 有効化のマイグレーションが適用済みであること（鍵をかけてからデータ投入）。
--   認証ユーザーのメールは example.invalid（実在しないTLD）。パスワードは設定しない（''）。
-- =============================================================

-- ---- 認証ユーザー（ログインの箱。パスワードは空＝実ログイン不可。テストはJWT擬似で行う） ----
insert into auth.users
  (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
   created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
   confirmation_token, email_change, email_change_token_new, recovery_token)
values
  ('00000000-0000-0000-0000-000000000000','aaaaaaaa-0000-0000-0000-000000000001','authenticated','authenticated','test-mas@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','',''),
  ('00000000-0000-0000-0000-000000000000','aaaaaaaa-0000-0000-0000-000000000002','authenticated','authenticated','test-area@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','',''),
  ('00000000-0000-0000-0000-000000000000','aaaaaaaa-0000-0000-0000-000000000003','authenticated','authenticated','test-tencho-a@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','',''),
  ('00000000-0000-0000-0000-000000000000','aaaaaaaa-0000-0000-0000-000000000004','authenticated','authenticated','test-tencho-b@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','',''),
  ('00000000-0000-0000-0000-000000000000','aaaaaaaa-0000-0000-0000-000000000005','authenticated','authenticated','test-shain@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','',''),
  ('00000000-0000-0000-0000-000000000000','aaaaaaaa-0000-0000-0000-000000000006','authenticated','authenticated','test-part1@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','',''),
  ('00000000-0000-0000-0000-000000000000','aaaaaaaa-0000-0000-0000-000000000007','authenticated','authenticated','test-part2@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','',''),
  ('00000000-0000-0000-0000-000000000000','aaaaaaaa-0000-0000-0000-000000000008','authenticated','authenticated','test-fc@example.invalid','',now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','','');

-- ---- 法人 ----
insert into companies (id, name, company_type) values
  ('cccccccc-0000-0000-0000-000000000001','テスト自社ホールディングス','own'),
  ('cccccccc-0000-0000-0000-000000000002','テストFCパートナー法人','fc_partner');

-- ---- 業態 ----
insert into brands (id, name, status) values
  ('bbbbbbbb-0000-0000-0000-000000000001','テスト業態yellow','active');

-- ---- エリア ----
insert into areas (id, name) values
  ('eeeeeeee-0000-0000-0000-000000000001','テスト東エリア'),
  ('eeeeeeee-0000-0000-0000-000000000002','テスト西エリア');

-- ---- 部署 ----
insert into departments (id, name) values
  ('dddddddd-0000-0000-0000-000000000001','テスト採用教育部');

-- ---- 店舗（直営3・FC1） ----
insert into stores (id, store_code, name, brand_id, area_id, company_id, operation_type, status, opened_on) values
  ('55555555-0000-0000-0000-000000000001','T001','テスト店舗A','bbbbbbbb-0000-0000-0000-000000000001','eeeeeeee-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001','direct','open', current_date - 365),
  ('55555555-0000-0000-0000-000000000002','T002','テスト店舗B','bbbbbbbb-0000-0000-0000-000000000001','eeeeeeee-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001','direct','open', current_date - 365),
  ('55555555-0000-0000-0000-000000000003','T003','テスト店舗C','bbbbbbbb-0000-0000-0000-000000000001','eeeeeeee-0000-0000-0000-000000000002','cccccccc-0000-0000-0000-000000000001','direct','open', current_date - 200),
  ('55555555-0000-0000-0000-000000000004','T004','テスト店舗D(FC)','bbbbbbbb-0000-0000-0000-000000000001','eeeeeeee-0000-0000-0000-000000000002','cccccccc-0000-0000-0000-000000000002','fc','open', current_date - 100);

-- ---- 店舗の外部連携ID（例） ----
insert into store_external_ids (store_id, provider, external_id) values
  ('55555555-0000-0000-0000-000000000001','dinii','TEST-DINII-A'),
  ('55555555-0000-0000-0000-000000000001','google_place','TEST-PLACE-A');

-- ---- ランク ----
insert into ranks (id, name, sort_order) values
  ('11111111-0000-0000-0000-000000000001','テストランナー',1),
  ('11111111-0000-0000-0000-000000000002','テストエール',2),
  ('11111111-0000-0000-0000-000000000003','テストサンメンバー',3);

-- ---- 人（社員番号・表示名のみ。本名などは people_private へ） ----
insert into people (id, employee_code, display_name, employment_status, joined_on, auth_user_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001','E001','テスト管理者',   'active', current_date - 700,'aaaaaaaa-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000002','E002','テストエリア長', 'active', current_date - 600,'aaaaaaaa-0000-0000-0000-000000000002'),
  ('aaaaaaaa-0000-0000-0000-000000000003','E003','テスト店長A',    'active', current_date - 500,'aaaaaaaa-0000-0000-0000-000000000003'),
  ('aaaaaaaa-0000-0000-0000-000000000004','E004','テスト店長B',    'active', current_date - 500,'aaaaaaaa-0000-0000-0000-000000000004'),
  ('aaaaaaaa-0000-0000-0000-000000000005','E005','テスト社員',     'active', current_date - 400,'aaaaaaaa-0000-0000-0000-000000000005'),
  ('aaaaaaaa-0000-0000-0000-000000000006','E006','テストアルバイト1','active', current_date - 200,'aaaaaaaa-0000-0000-0000-000000000006'),
  ('aaaaaaaa-0000-0000-0000-000000000007','E007','テストアルバイト2','active', current_date - 150,'aaaaaaaa-0000-0000-0000-000000000007'),
  ('aaaaaaaa-0000-0000-0000-000000000008','E008','テストFCオーナー','active', current_date - 100,'aaaaaaaa-0000-0000-0000-000000000008');

-- ---- 雇用区分の履歴（「社員」は アルバイト→社員 の履歴を持つ） ----
insert into employment_history (person_id, kind, start_on, end_on) values
  ('aaaaaaaa-0000-0000-0000-000000000001','employee',  current_date - 700, null),
  ('aaaaaaaa-0000-0000-0000-000000000002','employee',  current_date - 600, null),
  ('aaaaaaaa-0000-0000-0000-000000000003','employee',  current_date - 500, null),
  ('aaaaaaaa-0000-0000-0000-000000000004','employee',  current_date - 500, null),
  ('aaaaaaaa-0000-0000-0000-000000000005','part_time', current_date - 400, current_date - 60),  -- 最初はアルバイト
  ('aaaaaaaa-0000-0000-0000-000000000005','employee',  current_date - 59,  null),               -- → 社員に
  ('aaaaaaaa-0000-0000-0000-000000000006','part_time', current_date - 200, null),
  ('aaaaaaaa-0000-0000-0000-000000000007','part_time', current_date - 150, null),
  ('aaaaaaaa-0000-0000-0000-000000000008','fc_staff',  current_date - 100, null);

-- ---- 個人情報（架空） ----
insert into people_private (person_id, legal_name, contact, birth_date, monthly_salary, hourly_wage) values
  ('aaaaaaaa-0000-0000-0000-000000000001','架空 管理者','test-mas@example.invalid',  '1985-01-01', 600000, null),
  ('aaaaaaaa-0000-0000-0000-000000000002','架空 エリア長','test-area@example.invalid','1988-02-02', 450000, null),
  ('aaaaaaaa-0000-0000-0000-000000000003','架空 店長A','test-tencho-a@example.invalid','1990-03-03', 350000, null),
  ('aaaaaaaa-0000-0000-0000-000000000004','架空 店長B','test-tencho-b@example.invalid','1991-04-04', 350000, null),
  ('aaaaaaaa-0000-0000-0000-000000000005','架空 社員','test-shain@example.invalid',  '1995-05-05', 280000, null),
  ('aaaaaaaa-0000-0000-0000-000000000006','架空 アルバイト1','test-part1@example.invalid','2000-06-06', null, 1350),
  ('aaaaaaaa-0000-0000-0000-000000000007','架空 アルバイト2','test-part2@example.invalid','2001-07-07', null, 1350),
  ('aaaaaaaa-0000-0000-0000-000000000008','架空 FCオーナー','test-fc@example.invalid', '1980-08-08', null, null);

-- ---- 所属（店舗 または 部署） ----
insert into assignments (person_id, store_id, department_id, position, assignment_type, start_on) values
  ('aaaaaaaa-0000-0000-0000-000000000001', null,'dddddddd-0000-0000-0000-000000000001','本部','primary', current_date - 365),  -- MAS→部署
  ('aaaaaaaa-0000-0000-0000-000000000002', null,'dddddddd-0000-0000-0000-000000000001','エリア長','primary', current_date - 365),-- エリア長→部署
  ('aaaaaaaa-0000-0000-0000-000000000003','55555555-0000-0000-0000-000000000001', null,'店長','primary', current_date - 300), -- 店長A→店舗A
  ('aaaaaaaa-0000-0000-0000-000000000004','55555555-0000-0000-0000-000000000002', null,'店長','primary', current_date - 300), -- 店長B→店舗B
  ('aaaaaaaa-0000-0000-0000-000000000005','55555555-0000-0000-0000-000000000001', null,'一般','primary', current_date - 300), -- 社員→店舗A
  ('aaaaaaaa-0000-0000-0000-000000000006','55555555-0000-0000-0000-000000000001', null,'一般','primary', current_date - 200), -- アルバイト1→店舗A
  ('aaaaaaaa-0000-0000-0000-000000000007','55555555-0000-0000-0000-000000000002', null,'一般','primary', current_date - 150); -- アルバイト2→店舗B
  -- FCオーナーは店舗所属を持たず、法人付与で店舗Dが見える設計をテストする

-- ---- 権限（役割 × 範囲）。すべて start_on<=今日・end_on=null＝現在有効 ----
insert into role_grants (person_id, role, scope, scope_id, start_on, end_on) values
  ('aaaaaaaa-0000-0000-0000-000000000001','MAS', 'all',      null,                                   current_date - 365, null),
  ('aaaaaaaa-0000-0000-0000-000000000002','AREA','area',     'eeeeeeee-0000-0000-0000-000000000001', current_date - 365, null), -- 東エリア
  ('aaaaaaaa-0000-0000-0000-000000000003','LEA', 'store',    '55555555-0000-0000-0000-000000000001', current_date - 300, null), -- 店舗A
  ('aaaaaaaa-0000-0000-0000-000000000004','LEA', 'store',    '55555555-0000-0000-0000-000000000002', current_date - 300, null), -- 店舗B
  ('aaaaaaaa-0000-0000-0000-000000000005','MEM', 'store',    '55555555-0000-0000-0000-000000000001', current_date - 300, null), -- 社員・店舗A
  ('aaaaaaaa-0000-0000-0000-000000000006','PART','store',    '55555555-0000-0000-0000-000000000001', current_date - 200, null), -- アルバイト1・店舗A
  ('aaaaaaaa-0000-0000-0000-000000000007','PART','store',    '55555555-0000-0000-0000-000000000002', current_date - 150, null), -- アルバイト2・店舗B
  ('aaaaaaaa-0000-0000-0000-000000000008','FC',  'company',  'cccccccc-0000-0000-0000-000000000002', current_date - 100, null), -- FC法人
  -- 未来日付の権限テスト：社員に「10日後から」店舗BのLEA権限 → 今日はまだ無効（見えないはず）
  ('aaaaaaaa-0000-0000-0000-000000000005','LEA', 'store',    '55555555-0000-0000-0000-000000000002', current_date + 10,  null);

-- ---- ランク履歴 ----
insert into rank_history (person_id, rank_id, achieved_on, basis) values
  ('aaaaaaaa-0000-0000-0000-000000000003','11111111-0000-0000-0000-000000000003', current_date - 90, 'テスト:クエスト合格'),
  ('aaaaaaaa-0000-0000-0000-000000000005','11111111-0000-0000-0000-000000000002', current_date - 60, 'テスト:試験合格');


-- =========== 以下 お知らせ機能（STEP1）の架空データ ===========

-- エリア階層（追加1のテスト用）：親「関東」を作り、東エリアをその配下にする
insert into areas (id, name) values
  ('eeeeeeee-0000-0000-0000-000000000010','テスト関東エリア') on conflict (id) do nothing;
update areas set parent_area_id = 'eeeeeeee-0000-0000-0000-000000000010'
  where id = 'eeeeeeee-0000-0000-0000-000000000001'
    and parent_area_id is distinct from 'eeeeeeee-0000-0000-0000-000000000010';

-- 設定（1行だけ）
insert into app_settings (id, company_display_name, background_image_path) values
  (1, 'yellow.inc', null) on conflict (id) do nothing;

-- お知らせ本体（作成者=MAS）
insert into notices (id, title, body, is_important, status, published_at, created_by) values
  ('77777777-0000-0000-0000-000000000001','【重要】テスト全社お知らせ','全員向けの重要なお知らせです。',true ,'published', now(),                    'aaaaaaaa-0000-0000-0000-000000000001'),
  ('77777777-0000-0000-0000-000000000002','テスト：エール向け','ランク「テストエール」の人向け。',       false,'published', now(),                    'aaaaaaaa-0000-0000-0000-000000000001'),
  ('77777777-0000-0000-0000-000000000003','テスト：店舗A向け','店舗A所属の人向け。',                   false,'published', now(),                    'aaaaaaaa-0000-0000-0000-000000000001'),
  ('77777777-0000-0000-0000-000000000004','テスト：社員さん個人宛て','社員さん個人へのお知らせ。',       false,'published', now(),                    'aaaaaaaa-0000-0000-0000-000000000001'),
  ('77777777-0000-0000-0000-000000000005','テスト：下書き','まだ公開していない下書き。',               false,'draft',     null,                      'aaaaaaaa-0000-0000-0000-000000000001'),
  ('77777777-0000-0000-0000-000000000006','テスト：終了済み','終了したお知らせ。',                     false,'closed',    now() - interval '30 days','aaaaaaaa-0000-0000-0000-000000000001'),
  ('77777777-0000-0000-0000-000000000007','テスト：関東エリア向け','関東（親）向け。配下の東の店舗にも届く。',false,'published', now(),                  'aaaaaaaa-0000-0000-0000-000000000001'),
  ('77777777-0000-0000-0000-000000000008','テスト：西エリア向け','西エリア向け（東の人には届かない）。',   false,'published', now(),                    'aaaaaaaa-0000-0000-0000-000000000001'),
  ('77777777-0000-0000-0000-000000000009','テスト：店舗B向け','店舗B所属の人向け（Aの人には届かない）。', false,'published', now(),                    'aaaaaaaa-0000-0000-0000-000000000001')
on conflict (id) do nothing;

-- 対象
insert into notice_targets (id, notice_id, target_type, target_id) values
  ('88888888-0000-0000-0000-000000000001','77777777-0000-0000-0000-000000000001','all',   null),
  ('88888888-0000-0000-0000-000000000002','77777777-0000-0000-0000-000000000002','rank',  '11111111-0000-0000-0000-000000000002'),
  ('88888888-0000-0000-0000-000000000003','77777777-0000-0000-0000-000000000003','store', '55555555-0000-0000-0000-000000000001'),
  ('88888888-0000-0000-0000-000000000004','77777777-0000-0000-0000-000000000004','person','aaaaaaaa-0000-0000-0000-000000000005'),
  ('88888888-0000-0000-0000-000000000005','77777777-0000-0000-0000-000000000005','all',   null),
  ('88888888-0000-0000-0000-000000000006','77777777-0000-0000-0000-000000000006','all',   null),
  ('88888888-0000-0000-0000-000000000007','77777777-0000-0000-0000-000000000007','area',  'eeeeeeee-0000-0000-0000-000000000010'),
  ('88888888-0000-0000-0000-000000000008','77777777-0000-0000-0000-000000000008','area',  'eeeeeeee-0000-0000-0000-000000000002'),
  ('88888888-0000-0000-0000-000000000009','77777777-0000-0000-0000-000000000009','store', '55555555-0000-0000-0000-000000000002')
on conflict (id) do nothing;

-- 確認済みの記録（店長A・社員がいくつか確認済み）
insert into notice_acks (id, notice_id, person_id) values
  ('99999999-0000-0000-0000-000000000001','77777777-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000003'),
  ('99999999-0000-0000-0000-000000000002','77777777-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000005'),
  ('99999999-0000-0000-0000-000000000003','77777777-0000-0000-0000-000000000003','aaaaaaaa-0000-0000-0000-000000000005')
on conflict (id) do nothing;
