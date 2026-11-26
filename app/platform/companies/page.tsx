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
  return (
    <PlatformShell userName={me?.display_name ?? "運営"} dateStr={todayStr()} active="companies">
      <CompanyList companies={companies} homeTenantId={homeTenantId} />
    </PlatformShell>
  );
}
