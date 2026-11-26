import { createClient } from "@/lib/supabase/server";
import { getMe } from "@/lib/data";
import { todayStr } from "@/lib/platform-ui";
import PlatformShell from "@/components/platform/PlatformShell";

export default async function PlatformSettingsPage() {
  const supabase = await createClient();
  const me = await getMe(supabase);
  return (
    <PlatformShell userName={me?.display_name ?? "運営"} dateStr={todayStr()} active="settings">
      <div className="space-y-4">
        <h1 className="text-xl font-bold text-white">設定</h1>
        <p className="text-sm text-white/55">
          会社ごとの設定（会社名・アイコン・背景）や運営スタッフの管理は、ここに追加していきます（準備中）。
        </p>
      </div>
    </PlatformShell>
  );
}
