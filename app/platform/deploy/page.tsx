import { createClient } from "@/lib/supabase/server";
import { getMe } from "@/lib/data";
import { listTenants, listFeatures, listTenantFeatures, listLayers } from "@/lib/platform";
import { todayStr } from "@/lib/platform-ui";
import PlatformShell from "@/components/platform/PlatformShell";
import DeployView from "@/components/platform/DeployView";

export default async function DeployPage() {
  const supabase = await createClient();
  const [me, tenants, features, matrix, layers] = await Promise.all([
    getMe(supabase),
    listTenants(supabase),
    listFeatures(supabase),
    listTenantFeatures(supabase),
    listLayers(supabase),
  ]);
  return (
    <PlatformShell userName={me?.display_name ?? "運営"} dateStr={todayStr()} active="deploy">
      <DeployView layers={layers} features={features} tenants={tenants} matrix={matrix} />
    </PlatformShell>
  );
}
