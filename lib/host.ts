import type { SupabaseClient } from "@supabase/supabase-js";

// URL（ホスト名）→ どの会社か/運営かを「データ」から解決する（追加7）。
//   対応は tenant_hostnames テーブル（host_branding 関数で1件だけ取得）。
//   登録のないホストは unknown（入口を出さない）。
export type HostInfo =
  | { kind: "platform" }
  | {
      kind: "tenant";
      tenantId: string;
      slug: string;
      displayName: string;
      backgroundPath: string | null;
    }
  | { kind: "unknown" };

export async function resolveHost(
  supabase: SupabaseClient,
  host: string | null | undefined,
): Promise<HostInfo> {
  const h = (host ?? "").toLowerCase();
  try {
    const { data } = await supabase.rpc("host_branding", { p_host: h });
    const row = Array.isArray(data) ? data[0] : null;
    if (!row) return { kind: "unknown" };
    if (row.kind === "platform") return { kind: "platform" };
    return {
      kind: "tenant",
      tenantId: row.tenant_id,
      slug: row.slug,
      displayName: row.display_name,
      backgroundPath: row.background_image_path,
    };
  } catch {
    return { kind: "unknown" };
  }
}
