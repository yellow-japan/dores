import Link from "next/link";
import EnterCompany from "@/components/platform/EnterCompany";
import type { TenantRow } from "@/lib/platform";

const statusLabel: Record<string, { text: string; cls: string }> = {
  active: { text: "稼働中", cls: "text-emerald-300 bg-emerald-400/10 border-emerald-400/20" },
  preparing: { text: "準備中", cls: "text-amber-300 bg-amber-400/10 border-amber-400/20" },
  suspended: { text: "停止", cls: "text-white/50 bg-white/5 border-white/15" },
};

export default function CompanyList({
  companies,
  homeTenantId,
  homeHostByTenant,
}: {
  companies: TenantRow[];
  homeTenantId?: string | null;
  homeHostByTenant?: Record<string, string>; // 会社ID→URL（追加7・データ）。「開く」で使う
}) {
  return (
    <div>
      <div className="mb-4 flex items-baseline justify-between">
        <h1 className="text-xl font-bold text-white">会社</h1>
        <span className="text-sm text-white/50">入る会社を選んでください</span>
      </div>

      <ul className="space-y-2">
        {companies.map((c) => {
          const st = statusLabel[c.status] ?? statusLabel.suspended;
          return (
            <li
              key={c.id}
              className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/[0.03] p-3"
            >
              <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl border border-white/10 bg-white/[0.06] text-lg font-black text-white/90">
                {c.display_name.slice(0, 1).toUpperCase()}
              </div>
              <div className="min-w-0 flex-1">
                <div className="truncate font-bold text-white">{c.display_name}</div>
                <div className="truncate text-xs text-white/50">
                  店舗 {c.stores}・人 {c.people}
                </div>
              </div>
              <span className={`shrink-0 rounded-full border px-2.5 py-1 text-[11px] font-medium ${st.cls}`}>
                {st.text}
              </span>
              {c.id === homeTenantId ? (
                <Link
                  href={homeHostByTenant?.[c.id] ?? "/"}
                  className="shrink-0 rounded-xl border border-white/15 bg-white/10 px-4 py-2 text-sm font-bold text-white transition hover:bg-white/20"
                >
                  開く
                </Link>
              ) : (
                <EnterCompany tenantId={c.id} tenantName={c.display_name} />
              )}
            </li>
          );
        })}
      </ul>

      <div className="mt-5 flex flex-wrap gap-3 text-sm">
        <Link
          href="/platform/deploy"
          className="rounded-xl border border-white/10 bg-white/[0.03] px-4 py-2 text-white/80 hover:bg-white/[0.07]"
        >
          開発と反映へ
        </Link>
        <Link
          href="/platform/records"
          className="rounded-xl border border-white/10 bg-white/[0.03] px-4 py-2 text-white/80 hover:bg-white/[0.07]"
        >
          入った記録を見る
        </Link>
      </div>
    </div>
  );
}
