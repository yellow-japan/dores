-- =============================================================
-- notice_target_person_ids を、MAS・管理職(エリア長/店長)以外が呼んだら
-- 何も返さないように作り直す（二重の安全策）。
--   呼び出し側(確認状況ページ)でも制限しているが、関数自体でも制限する。
-- =============================================================
create or replace function notice_target_person_ids(p_notice uuid)
returns setof uuid language sql stable security definer set search_path = public, pg_temp as $$
  select pid
  from (
    -- 全員
    select p.id as pid
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
    -- ランク（現在のランク）
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
    -- エリア（対象エリア＋配下エリア）に属する店舗の現在所属
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
          select ar.id from areas ar join desc_areas d on ar.parent_area_id = d.id
        )
        select id from desc_areas
      )
  ) ids
  -- 呼び出した人が MAS・管理職(AREA/LEA)のときだけ返す。それ以外は0件。
  where exists (
    select 1 from role_grants g
    where g.person_id = current_person_id()
      and g.role in ('MAS', 'AREA', 'LEA')
      and g.start_on <= current_date and g.end_on is null
  );
$$;

revoke execute on function notice_target_person_ids(uuid) from public;
revoke execute on function notice_target_person_ids(uuid) from anon;
grant  execute on function notice_target_person_ids(uuid) to authenticated;
