import { createClient } from "@/lib/supabase/server";
import { getMe } from "@/lib/data";
import { platformStats } from "@/lib/platform";
import { todayStr } from "@/lib/platform-ui";
import PlatformShell from "@/components/platform/PlatformShell";
import PlatformHome from "@/components/platform/PlatformHome";

export default async function PlatformHomePage() {
  const supabase = await createClient();
  const [me, stats] = await Promise.all([getMe(supabase), platformStats(supabase)]);
  const userName = me?.display_name ?? "運営";
  return (
    <PlatformShell userName={userName} dateStr={todayStr()} active="home">
      <PlatformHome userName={userName} stats={stats} />
    </PlatformShell>
  );
}
