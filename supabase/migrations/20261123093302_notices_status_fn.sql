-- =============================================================
-- お知らせの「対象者」を展開する関数（確認状況の集計に使う）
--   全員 / 個人 / ランク（現在ランク）/ 店舗（現在所属）/ エリア（配下エリアも含む）
--   security definer（横断的に読む）・anon不可。返すのは person_id の集合。
--   ※ 実際に誰の分を見せるかは、呼び出し側で people/notice_acks の RLS により絞られる。
-- =============================================================
create or replace function notice_target_person_ids(p_notice uuid)
returns setof uuid language sql stable security definer set search_path = public, pg_temp as $$
  -- 全員
  select p.id
  from people p
  where exists (
    select 1 from notice_targets t
    where t.notice_id = p_notice and t.active and t.target_type = 'all'
  )
  union
  -- 個人
  select t.target_id
  from notice_targets t
  where t.notice_id = p_notice and t.active and t.target_type = 'person' and t.target_id is not null
  union
  -- ランク（現在のランク＝rank_history の最新）
  select p.id
  from people p
  join lateral (
    select rh.rank_id from rank_history rh
    where rh.person_id = p.id
    order by rh.achieved_on desc, rh.created_at desc
    limit 1
  ) cr on true
  where exists (
    select 1 from notice_targets t
    where t.notice_id = p_notice and t.active and t.target_type = 'rank' and t.target_id = cr.rank_id
  )
  union
  -- 店舗（現在の所属）
  select a.person_id
  from assignments a
  where a.store_id is not null and a.start_on <= current_date and a.end_on is null
    and exists (
      select 1 from notice_targets t
      where t.notice_id = p_notice and t.active and t.target_type = 'store' and t.target_id = a.store_id
    )
  union
  -- エリア（対象エリア＋その配下エリア）に属する店舗の現在所属
  select a.person_id
  from assignments a
  join stores s on s.id = a.store_id
  where a.store_id is not null and a.start_on <= current_date and a.end_on is null
    and s.area_id in (
      with recursive desc_areas(id) as (
        select t.target_id
        from notice_targets t
        where t.notice_id = p_notice and t.active and t.target_type = 'area' and t.target_id is not null
        union
        select ar.id
        from areas ar
        join desc_areas d on ar.parent_area_id = d.id
      )
      select id from desc_areas
    );
$$;

revoke execute on function notice_target_person_ids(uuid) from public;
revoke execute on function notice_target_person_ids(uuid) from anon;
grant  execute on function notice_target_person_ids(uuid) to authenticated;
