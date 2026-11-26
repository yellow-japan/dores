import { cache } from "react";
import type { SupabaseClient } from "@supabase/supabase-js";

// DO'reS運営スタッフか
export const getIsPlatformAdmin = cache(
  async (supabase: SupabaseClient): Promise<boolean> => {
    const { data } = await supabase.rpc("is_platform_admin");
    return data === true;
  },
);

export type TenantRow = {
  id: string;
  slug: string;
  display_name: string;
  status: string;
  stores: number;
  people: number;
};

// 会社一覧（運営は全社見える）。件数は tenant_features などの行数ではなく実データから。
export async function listTenants(supabase: SupabaseClient): Promise<TenantRow[]> {
  const { data: tenants } = await supabase
    .from("tenants")
    .select("id, slug, display_name, status")
    .order("slug");
  const rows = tenants ?? [];
  // 店舗数・人数（運営は acting 無しでも tenants は見えるが、店舗/人は会社ごとに数える必要がある）
  const result: TenantRow[] = [];
  for (const t of rows) {
    const [{ count: stores }, { count: people }] = await Promise.all([
      supabase.from("stores").select("id", { count: "exact", head: true }).eq("tenant_id", t.id),
      supabase.from("people").select("id", { count: "exact", head: true }).eq("tenant_id", t.id),
    ]);
    result.push({
      id: t.id,
      slug: t.slug,
      display_name: t.display_name,
      status: t.status,
      stores: stores ?? 0,
      people: people ?? 0,
    });
  }
  return result;
}

export type FeatureRow = {
  key: string;
  name: string;
  description: string | null;
  stage: string;
  layer: string | null;
  current_version: string;
};

export async function listFeatures(supabase: SupabaseClient): Promise<FeatureRow[]> {
  const { data } = await supabase
    .from("features")
    .select("key, name, description, stage, layer, current_version")
    .order("sort_order");
  return data ?? [];
}

export type TenantFeatureRow = {
  tenant_id: string;
  feature_key: string;
  state: string;
  enabled_version: string | null;
};

export async function listTenantFeatures(
  supabase: SupabaseClient,
): Promise<TenantFeatureRow[]> {
  const { data } = await supabase
    .from("tenant_features")
    .select("tenant_id, feature_key, state, enabled_version");
  return data ?? [];
}

export type LayerRow = { layer: string; label: string; description: string | null; required: boolean };

export async function listLayers(supabase: SupabaseClient): Promise<LayerRow[]> {
  const { data } = await supabase
    .from("feature_layers")
    .select("layer, label, description, required")
    .order("sort_order");
  return data ?? [];
}

// DO'reSホームの3つの数字
export async function platformStats(supabase: SupabaseClient) {
  const [{ count: companies }, feats, tfs] = await Promise.all([
    supabase.from("tenants").select("id", { count: "exact", head: true }),
    supabase.from("features").select("key, stage, current_version"),
    supabase.from("tenant_features").select("feature_key, enabled_version"),
  ]);
  const features = feats.data ?? [];
  const developing = features.filter(
    (f) => f.stage === "developing" || f.stage === "testing",
  ).length;
  // 反映待ち: 完成(done)の機能で、最新版でない会社の数
  const latest = new Map(features.map((f) => [f.key, f.current_version]));
  const pending = (tfs.data ?? []).filter((tf) => {
    const cur = latest.get(tf.feature_key);
    return cur && tf.enabled_version && tf.enabled_version !== cur;
  }).length;
  return { companies: companies ?? 0, developing, pending };
}
