import { cache } from "react";
import type { SupabaseClient } from "@supabase/supabase-js";

export type Me = { id: string; display_name: string } | null;

// ログイン中の本人（people 行）。my_person() で取得（運営が他社に入っている間でも自分を取れる）。
export const getMe = cache(async (supabase: SupabaseClient): Promise<Me> => {
  const { data } = await supabase.rpc("my_person");
  const row = Array.isArray(data) ? data[0] : null;
  return row ? { id: row.id, display_name: row.display_name } : null;
});

// 会社名と背景画像URL：いま「見ている会社（acting）」のもの。
//   運営が他社に入っていればその会社名・背景、ふだんは自分の会社。
export async function getBranding(
  supabase: SupabaseClient,
): Promise<{ companyName: string; backgroundUrl: string }> {
  const { data: actingId } = await supabase.rpc("current_acting_tenant_id");

  let companyName = "yellow.inc";
  let bgPath: string | null = null;
  if (actingId) {
    const { data } = await supabase
      .from("tenants")
      .select("display_name, background_image_path")
      .eq("id", actingId)
      .maybeSingle();
    if (data) {
      companyName = data.display_name;
      bgPath = data.background_image_path;
    }
  }

  let backgroundUrl = "/default-bg.jpg";
  if (bgPath) {
    const { data: signed } = await supabase.storage
      .from("branding")
      .createSignedUrl(bgPath, 3600);
    if (signed?.signedUrl) backgroundUrl = signed.signedUrl;
  }
  return { companyName, backgroundUrl };
}

// 本部管理者(MAS)か。cache() で重複呼び出しをまとめる。
export const getIsMas = cache(async (supabase: SupabaseClient): Promise<boolean> => {
  const { data } = await supabase.rpc("is_mas");
  return data === true;
});

// お知らせの確認状況を見られる人か（MAS / エリア長 / 店長）
export async function canManageNotices(
  supabase: SupabaseClient,
  meId: string,
): Promise<boolean> {
  const { data } = await supabase
    .from("role_grants")
    .select("id")
    .eq("person_id", meId)
    .in("role", ["MAS", "AREA", "LEA"])
    .is("end_on", null)
    .lte("start_on", new Date().toISOString().slice(0, 10))
    .limit(1);
  return (data?.length ?? 0) > 0;
}

// お知らせ作成/編集フォーム用の選択肢（MASはすべて読める）
export async function loadNoticeOptions(supabase: SupabaseClient) {
  const [stores, areas, ranks, people] = await Promise.all([
    supabase.from("stores").select("id, name").order("store_code"),
    supabase.from("areas").select("id, name").order("name"),
    supabase.from("ranks").select("id, name").order("sort_order"),
    supabase.from("people").select("id, display_name").order("employee_code"),
  ]);
  return {
    stores: (stores.data ?? []).map((s) => ({ id: s.id, name: s.name })),
    areas: (areas.data ?? []).map((a) => ({ id: a.id, name: a.name })),
    ranks: (ranks.data ?? []).map((r) => ({ id: r.id, name: r.name })),
    people: (people.data ?? []).map((p) => ({ id: p.id, name: p.display_name })),
  };
}

// 今いる店舗（主所属・現在）の名前
export async function getStoreName(
  supabase: SupabaseClient,
  meId: string,
): Promise<string | null> {
  const { data: a } = await supabase
    .from("assignments")
    .select("store_id")
    .eq("person_id", meId)
    .is("end_on", null)
    .eq("assignment_type", "primary")
    .not("store_id", "is", null)
    .limit(1)
    .maybeSingle();
  if (!a?.store_id) return null;
  const { data: s } = await supabase
    .from("stores")
    .select("name")
    .eq("id", a.store_id)
    .maybeSingle();
  return s?.name ?? null;
}
