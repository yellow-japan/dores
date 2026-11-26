-- =============================================================
-- DO'reS STEP3 テストデータ: 機能の表示・開発と反映（すべて架空）
--   seed.sql / seed_notices.sql / seed_tenant_b.sql / seed_platform.sql の後に実行。
--   ・テスト株式会社B は お知らせ「使える」だが、バージョンは v1.0（＝yellowのv1.1にまだ反映していない）。
--   ・層(THINKING/DOING/FUTURE)の見本として、まだ無い機能も少し入れる（架空）。
-- =============================================================

-- 見本の機能（架空・まだ作っていない）。分類(層)と段階の見本。
--   分類: シフト=DOING(行動する) / レポート=FUTURE(未来をつくる)
insert into features (key, name, description, stage, layer, current_version, sort_order) values
  ('shifts', 'シフト',   'シフトの作成と共有（構想）', 'planning', 'DOING',  'v0.1', 2),
  ('reports','レポート', '月次レポート（将来）',       'planning', 'FUTURE', 'v0.1', 3)
on conflict (key) do nothing;

-- テスト株式会社B の機能設定
--   お知らせ: 使える・ただし v1.0（yellow は v1.1。Bはまだ新バージョンに反映していない）
insert into tenant_features (tenant_id, feature_key, state, enabled_version) values
  ('0000ffff-0000-0000-0000-000000000002','notices','available','v1.0'),
  -- 見本: Bはシフト準備中・レポート出さない
  ('0000ffff-0000-0000-0000-000000000002','shifts','preparing', null),
  ('0000ffff-0000-0000-0000-000000000002','reports','hidden',   null)
on conflict (tenant_id, feature_key) do nothing;

-- 見本: yellow はシフト準備中・レポート出さない
insert into tenant_features (tenant_id, feature_key, state, enabled_version) values
  ('0000ffff-0000-0000-0000-000000000001','shifts','preparing', null),
  ('0000ffff-0000-0000-0000-000000000001','reports','hidden',   null)
on conflict (tenant_id, feature_key) do nothing;
