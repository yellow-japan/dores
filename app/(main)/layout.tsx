import { createClient } from "@/lib/supabase/server";
import AppShell from "@/components/AppShell";
import OpsBanner from "@/components/platform/OpsBanner";
import { getMe, getBranding, getStoreName } from "@/lib/data";

const PLATFORM_URL =
  process.env.NEXT_PUBLIC_PLATFORM_URL ?? "https://dores-home.vercel.app";

export default async function MainLayout({ children }: { children: React.ReactNode }) {
  // 未ログインは middleware が /login に送るので、ここでは本人情報と設定を並行取得する
  const supabase = await createClient();
  const [me, branding] = await Promise.all([getMe(supabase), getBranding(supabase)]);
  const storeName = me ? await getStoreName(supabase, me.id) : null;

  // DO'reS運営として「所属以外の会社に入っている」間だけ、上に帯を出す（追加2）
  let ops: { companyName: string; sessionId: string } | null = null;
  if (me) {
    const { data: homeTenantId } = await supabase.rpc("current_tenant_id");
    const { data: sess } = await supabase
      .from("company_access_sessions")
      .select("id, target_tenant_id, tenants(display_name)")
      .is("exited_at", null)
      .order("entered_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    const s = sess as unknown as
      | { id: string; target_tenant_id: string; tenants: { display_name: string } | null }
      | null;
    if (s && homeTenantId && s.target_tenant_id !== homeTenantId) {
      ops = { companyName: s.tenants?.display_name ?? "会社", sessionId: s.id };
    }
  }

  return (
    <>
      {ops && (
        <OpsBanner
          companyName={ops.companyName}
          sessionId={ops.sessionId}
          platformUrl={PLATFORM_URL}
        />
      )}
      <AppShell
        companyName={branding.companyName}
        storeName={storeName}
        backgroundUrl={branding.backgroundUrl}
      >
        {children}
      </AppShell>
    </>
  );
}
