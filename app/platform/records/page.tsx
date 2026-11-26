import { createClient } from "@/lib/supabase/server";
import { getMe } from "@/lib/data";
import { todayStr } from "@/lib/platform-ui";
import PlatformShell from "@/components/platform/PlatformShell";

function fmt(ts: string | null): string {
  if (!ts) return "";
  return new Date(ts).toLocaleString("ja-JP", { month: "numeric", day: "numeric", hour: "2-digit", minute: "2-digit" });
}

export default async function RecordsPage() {
  const supabase = await createClient();
  const me = await getMe(supabase);
  const [sessions, logs] = await Promise.all([
    supabase
      .from("company_access_sessions")
      .select("id, target_tenant_id, reason, entered_at, exited_at, tenants(display_name)")
      .order("entered_at", { ascending: false })
      .limit(20),
    supabase
      .from("feature_admin_log")
      .select("id, action, layer, feature_key, detail, at")
      .order("at", { ascending: false })
      .limit(20),
  ]);

  const sess = (sessions.data ?? []) as unknown as {
    id: string; reason: string | null; entered_at: string; exited_at: string | null;
    tenants: { display_name: string } | null;
  }[];
  const log = logs.data ?? [];

  return (
    <PlatformShell userName={me?.display_name ?? "運営"} dateStr={todayStr()} active="records">
      <div className="space-y-6">
        <h1 className="text-xl font-bold text-white">記録</h1>

        <section>
          <h2 className="mb-2 text-sm font-bold text-white/80">会社に入った記録</h2>
          <ul className="space-y-1.5">
            {sess.length === 0 && <li className="text-sm text-white/40">まだありません</li>}
            {sess.map((s) => (
              <li key={s.id} className="rounded-xl border border-white/10 bg-white/[0.03] px-3 py-2 text-sm">
                <span className="font-medium text-white">{s.tenants?.display_name ?? "—"}</span>
                <span className="ml-2 text-white/45">{fmt(s.entered_at)}</span>
                {s.exited_at ? (
                  <span className="ml-2 text-white/40">退出 {fmt(s.exited_at)}</span>
                ) : (
                  <span className="ml-2 rounded-full bg-emerald-400/10 px-2 py-0.5 text-[11px] text-emerald-300">入室中</span>
                )}
                {s.reason && <span className="ml-2 text-white/50">「{s.reason}」</span>}
              </li>
            ))}
          </ul>
        </section>

        <section>
          <h2 className="mb-2 text-sm font-bold text-white/80">機能設定の操作記録</h2>
          <ul className="space-y-1.5">
            {log.length === 0 && <li className="text-sm text-white/40">まだありません</li>}
            {log.map((l) => (
              <li key={l.id} className="rounded-xl border border-white/10 bg-white/[0.03] px-3 py-2 text-sm">
                <span className="rounded-md border border-white/15 bg-white/5 px-1.5 py-0.5 text-[11px] text-white/70">{l.action}</span>
                <span className="ml-2 text-white/80">{l.feature_key ?? l.layer ?? ""}</span>
                <span className="ml-2 text-white/45">{l.detail}</span>
                <span className="ml-2 text-white/35">{fmt(l.at)}</span>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </PlatformShell>
  );
}
