import { createClient } from "@/lib/supabase/server";
import { getMe } from "@/lib/data";
import { listTenants } from "@/lib/platform";
import { todayStr } from "@/lib/platform-ui";
import PlatformShell from "@/components/platform/PlatformShell";
import CompanyList from "@/components/platform/CompanyList";

export default async function CompaniesPage() {
  const supabase = await createClient();
  const [me, companies] = await Promise.all([getMe(supabase), listTenants(supabase)]);
  // 自分の所属会社（ここは「開く」、他社は「入る」）
  let homeTenantId: string | null = null;
  if (me) {
    const { data } = await supabase.from("people").select("tenant_id").eq("id", me.id).maybeSingle();
    homeTenantId = data?.tenant_id ?? null;
  }
  // 会社ID→URL（追加7・データ）。vercel.app のホストを使う。
  const { data: hosts } = await supabase
    .from("tenant_hostnames")
    .select("hostname, tenant_id, kind");
  const homeHostByTenant: Record<string, string> = {};
  for (const row of hosts ?? []) {
    if (row.kind === "tenant" && row.tenant_id && row.hostname.endsWith(".vercel.app")) {
      if (!homeHostByTenant[row.tenant_id]) homeHostByTenant[row.tenant_id] = `https://${row.hostname}`;
    }
  }
  return (
    <PlatformShell userName={me?.display_name ?? "運営"} dateStr={todayStr()} active="companies">
      <CompanyList
        companies={companies}
        homeTenantId={homeTenantId}
        homeHostByTenant={homeHostByTenant}
      />
    </PlatformShell>
  );
}
