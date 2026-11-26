-- =============================================================
-- DO'reS STEP2 テストデータ: 運営スタッフと「入る許可」（すべて架空）
--   seed.sql / seed_notices.sql / seed_tenant_b.sql の後に実行する。
--   テスト用に、yellow の人を DO'reS運営の役として流用する（本物の運営名簿ではない）。
--     代表(aaaa…001)   = DO'reS運営スタッフ。B社に運営サポートで入れる。
--     エリア長(aaaa…002) = B社に運営サポートで入れる＋B社の個人情報の期限付き許可あり（テスト用）。
--     店長A(aaaa…003)   = B社にコンサル担当の許可（ただしコンサルは未有効＝入れない）。
-- =============================================================

-- DO'reS運営スタッフ（最初は代表のみ）
insert into platform_admins (person_id, note) values
  ('aaaaaaaa-0000-0000-0000-000000000001','テスト: 代表＝DO''reS運営')
on conflict (person_id) do nothing;

-- 所属以外の会社(B)に入る許可
insert into company_access_grants (id, person_id, target_tenant_id, access_kind, reason, granted_by, status, start_on) values
  ('0000aaaa-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','0000ffff-0000-0000-0000-000000000002','ops_support','テスト:運営サポート','aaaaaaaa-0000-0000-0000-000000000001','active', current_date - 1),
  ('0000aaaa-0000-0000-0000-000000000002','aaaaaaaa-0000-0000-0000-000000000002','0000ffff-0000-0000-0000-000000000002','ops_support','テスト:運営サポート','aaaaaaaa-0000-0000-0000-000000000001','active', current_date - 1),
  ('0000aaaa-0000-0000-0000-000000000003','aaaaaaaa-0000-0000-0000-000000000003','0000ffff-0000-0000-0000-000000000002','consultant','テスト:コンサル(準備のみ)','aaaaaaaa-0000-0000-0000-000000000001','active', current_date - 1)
on conflict (id) do nothing;

-- 個人情報の期限付き許可（B社のMASが、エリア長にB社の個人情報を見せる。期限7日）
insert into private_access_grants (id, person_id, target_tenant_id, granted_by, status, start_on, end_on) values
  ('0000aaaa-0000-0000-0000-0000000000f1','aaaaaaaa-0000-0000-0000-000000000002','0000ffff-0000-0000-0000-000000000002','0000bbbb-0000-0000-0000-000000000001','active', current_date - 1, current_date + 7)
on conflict (id) do nothing;
