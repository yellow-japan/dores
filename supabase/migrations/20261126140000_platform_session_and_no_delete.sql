-- =============================================================
-- DO'reS STEP2 追加修正（代表レビュー2点）
--   1. 所属以外の会社として動けるのは「入った記録(company_access_sessions)が開いていて、
--      出ていない・入ってから8時間以内」のときだけにする。
--      （許可があるだけ・画面が指定しただけでは動かない。記録を開かず入ろうとしたら自社に戻る）
--   2. 業務の表（共通マスター13表など）の削除ポリシー(_del)を作らない。
--      承認済みの設計どおり「削除しない（状態で表す）」。MASでも削除できない。
--
--   ※ 適用済みマイグレーションは変更せず、この新しい1本で直す。
-- =============================================================

-- -------------------------------------------------------------
-- 1. current_acting_tenant_id(): 「開いている・新しい入室記録」が必要
--    条件: 本人の company_access_sessions で、request.acting_tenant と一致し、
--          exited_at が空（出ていない）、entered_at が8時間以内、かつ今も入れる許可(can_enter_tenant)。
--    どれか欠ければ必ず自分の所属会社に戻る（DBで保証）。
-- -------------------------------------------------------------
create or replace function current_acting_tenant_id()
returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce(
    (
      select s.target_tenant_id
      from company_access_sessions s
      where s.person_id = current_person_id()
        and s.target_tenant_id = nullif(current_setting('request.acting_tenant', true), '')::uuid
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
  '今どの会社として動いているか。開いている入室記録(8時間以内)＋有効な許可があるときだけその会社。無ければ自分の所属会社。';

-- -------------------------------------------------------------
-- 2. 業務13表の削除ポリシー(_del)を削除 → 誰も（MASでも）削除できない（削除しない設計）
-- -------------------------------------------------------------
do $$
declare
  t    text;
  tbls constant text[] := array[
    'companies','brands','areas','departments','ranks','stores','store_external_ids',
    'people','employment_history','people_private','assignments','role_grants','rank_history'
  ];
begin
  foreach t in array tbls loop
    execute format('drop policy if exists %I on %I', t||'_del', t);
  end loop;
end $$;
