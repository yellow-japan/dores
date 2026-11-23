-- =============================================================
-- DO'reS お知らせ STEP1 追加修正
--  1. 新しい判定関数を anon からも明示的に実行不可にする
--     （Supabaseは初期設定で anon に EXECUTE を付けるため、public の revoke だけでは残る）
--  2. notice_acks.acked_at は、本人が値を指定しても必ず now() にする（トリガー）
-- =============================================================

-- 1. anon から明示的に EXECUTE を剥奪
revoke execute on function current_rank_id()       from anon;
revoke execute on function my_area_ids()           from anon;
revoke execute on function notice_is_target(uuid)  from anon;

-- 2. 確認日時は常にサーバー時刻 now()（クライアント指定値は無視）
create or replace function force_acked_at_now()
returns trigger language plpgsql as $$
begin
  new.acked_at := now();
  return new;
end $$;

create trigger trg_notice_acks_force_acked_at
  before insert on notice_acks
  for each row execute function force_acked_at_now();
