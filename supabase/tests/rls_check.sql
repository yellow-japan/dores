-- =============================================================
-- DO'reS 権限(RLS) 手動チェック（dores-dev の SQL Editor に貼って実行）
--   前提: RLSマイグレーション適用済み ＋ seed.sql 投入済み。
--   各ブロックで「テスト用ユーザーとしてログインした状態」を擬似再現して確認する。
--   service_role ではなく authenticated ロールで確認する（service_roleはRLSを素通りするため）。
--   ※ パスワードは使わない。JWTのsub（人のauth_user_id）だけで擬似ログインする。
-- =============================================================

-- ① 未ログイン(anon)：どの表も 0 件であること（#2）
set role anon;
select 'anon stores(期待0)='          || count(*) from stores;
select 'anon people(期待0)='          || count(*) from people;
select 'anon people_private(期待0)='  || count(*) from people_private;
reset role;

-- ② MAS：全部見える
set role authenticated;
select set_config('request.jwt.claims','{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', false);
select 'MAS stores(期待4)='         || count(*) from stores;
select 'MAS people(期待8)='         || count(*) from people;
select 'MAS people_private(期待8)=' || count(*) from people_private;
reset role;

-- ③ 店長A：自店Aだけ。名簿はA所属の3人。個人情報は自分だけ
set role authenticated;
select set_config('request.jwt.claims','{"sub":"aaaaaaaa-0000-0000-0000-000000000003","role":"authenticated"}', false);
select '店長A stores(期待1)='                || count(*) from stores;
select '店長A うちB(期待0)='                 || count(*) from stores where id='55555555-0000-0000-0000-000000000002';
select '店長A people(期待3)='                || count(*) from people;
select '店長A people_private 自分のみ(期待1)='|| count(*) from people_private;
reset role;

-- ④ エリア長：担当エリア(東)の全店A・B（2件）。西のCは見えない
set role authenticated;
select set_config('request.jwt.claims','{"sub":"aaaaaaaa-0000-0000-0000-000000000002","role":"authenticated"}', false);
select 'エリア長 stores(期待2)='   || count(*) from stores;
select 'エリア長 うちC西(期待0)='  || count(*) from stores where id='55555555-0000-0000-0000-000000000003';
select 'エリア長 people(期待6)='   || count(*) from people;
reset role;

-- ⑤ アルバイト1：自分の情報だけ（名簿も個人情報も自分のみ）
set role authenticated;
select set_config('request.jwt.claims','{"sub":"aaaaaaaa-0000-0000-0000-000000000006","role":"authenticated"}', false);
select 'アルバイト1 people(期待1)='         || count(*) from people;
select 'アルバイト1 people_private(期待1)=' || count(*) from people_private;
reset role;

-- ⑥ 社員(MEM)：未来日付のB権限は無効（#4）。Bは見えない
set role authenticated;
select set_config('request.jwt.claims','{"sub":"aaaaaaaa-0000-0000-0000-000000000005","role":"authenticated"}', false);
select '社員 stores(期待1)='           || count(*) from stores;
select '社員 未来権限のB(期待0)='      || count(*) from stores where id='55555555-0000-0000-0000-000000000002';
reset role;

-- ⑦ FCオーナー：自社のFC店Dだけ
set role authenticated;
select set_config('request.jwt.claims','{"sub":"aaaaaaaa-0000-0000-0000-000000000008","role":"authenticated"}', false);
select 'FC stores(期待1)='      || count(*) from stores;
select 'FC うちD(期待1)='       || count(*) from stores where id='55555555-0000-0000-0000-000000000004';
reset role;

-- ⑧ 書き込み制限（#7）：店長Aは店舗を更新できない（0行のはず）
set role authenticated;
select set_config('request.jwt.claims','{"sub":"aaaaaaaa-0000-0000-0000-000000000003","role":"authenticated"}', false);
with up as (update stores set name=name where id='55555555-0000-0000-0000-000000000001' returning 1)
select '店長A 更新できた行数(期待0)=' || count(*) from up;
reset role;

-- ⑨ 書き込み（#7）：MASは店舗を更新できる（1行のはず）
set role authenticated;
select set_config('request.jwt.claims','{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}', false);
with up as (update stores set name=name where id='55555555-0000-0000-0000-000000000001' returning 1)
select 'MAS 更新できた行数(期待1)=' || count(*) from up;
reset role;
